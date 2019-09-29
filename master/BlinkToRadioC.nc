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

  uint16_t counter; //controls the led which should be turned on according to which slave node sends the message
  message_t pkt;
  bool busy = FALSE;
  

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call Timer0.startPeriodic(3000); //check each 3 seconds if a node disconnected
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void Timer0.fired() {
    call Leds.led0Off(); //Turn the led off, in case the related node is still sending message, the led will go on right away again
    call Leds.led1Off();
    call Leds.led2Off();
    
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(BlinkToRadioMsg)) {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
if (btrpkt -> counter ==0) 
{     
 call Leds.led0On(); //if slave node1 sends the message, turn led0 on
}
if (btrpkt -> counter ==1)
{
	call Leds.led1On(); //if slave node2 sends the message, turn led1 on
    }
}
    return msg;
  
}
}
