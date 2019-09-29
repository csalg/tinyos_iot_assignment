#include <Timer.h>
#include "BlinkToRadio.h"

module BlinkToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation {

  message_t pkt;
  bool busy = FALSE;
  uint16_t ledToTurnOn = 0; //each slave node specifies which led the master node should turn on when it receive a message from this node
  void setLeds(uint16_t val) {
  }

  event void Boot.booted() {
    call AMControl.start(); // This starts the radio. 
  }

  event void AMControl.startDone(error_t err) { // This SplitControl component is a generic interface for controlling things, in this case the radio.
    if (err == SUCCESS) { // err can be SUCCESS or FAILURE
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) { // This is here because its an event so it has to be implemented.
  }

  event void Timer0.fired() { //send ledToTurnOn periodically to update the master node
    if (!busy) {
      BlinkToRadioMsg* btrpkt = 
	(BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg))); 
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->nodeid = TOS_NODE_ID; 
      btrpkt->counter = ledToTurnOn;
      if (call AMSend.send(AM_BROADCAST_ADDR, // AMSend is synchronous and returns an error. AM_BROADCAST_ADDR specifies broadcast to all addresses in range.
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
      }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    return msg;
  }
}
