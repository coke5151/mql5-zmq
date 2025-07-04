//+------------------------------------------------------------------+
//|                                                    TaskEvent.mq4 |
//|                  Copyright 2017, Bear Two Technologies Co., Ltd. |
//|                                                dingmaotu@126.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Bear Two Technologies Co., Ltd."
#property link "dingmaotu@126.com"
#property version "1.00"
#property strict

#include <Zmq/Zmq.mqh>

#define within(num) (int)((float)num * MathRand() / (32767 + 1.0))
//+------------------------------------------------------------------+
//| Task ventilator in MQL (adapted from the C++ version)            |
//| Binds PUSH socket to tcp://localhost:5557                        |
//| Sends batch of tasks to workers via that socket                  |
//|                                                                  |
//| Olivier Chamoux <olivier.chamoux@fr.thalesgroup.com>             |
//+------------------------------------------------------------------+
void OnStart()
{
    Context context;

    //--- Socket to send messages on
    Socket sender(context, ZMQ_PUSH);
    sender.bind("tcp://*:5557");

    //--- Block execution of Script: please start workers in another terminal
    MessageBox("Start workers in another terminal and press Enter if they are ready.", "Wait for workers...", MB_OK | MB_ICONINFORMATION);
    Print("Sending tasks to workers…");

    //--- The first message is "0" and signals start of batch
    Socket sink(context, ZMQ_PUSH);
    sink.connect("tcp://localhost:5558");
    ZmqMsg message("0");
    sink.send(message);

    //--- Initialize random number generator
    MathSrand(GetTickCount());

    //--- Send 100 tasks
    int totalMillis = 0; //--- Total expected cost in msecs
    for (int i = 0; i < 100; i++)
    {
        //--- Random workload from 1 to 100msecs
        int workload = within(100) + 1;
        totalMillis += workload;
        message.rebuild(IntegerToString(workload));
        sender.send(message);
    }
    Print("Total expected cost: ", totalMillis, " msec");
    Sleep(1000); //--- Give 0MQ time to deliver
}
//+------------------------------------------------------------------+
