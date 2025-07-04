//+------------------------------------------------------------------+
//|                                          WeatherUpdateClient.mq4 |
//|                                          Copyright 2016, Li Ding |
//|                                            dingmaotu@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Li Ding"
#property link "dingmaotu@hotmail.com"
#property version "1.00"
#property strict

input string InpZipCode = "10001"; // ZipCode to subscribe to, default is NYC, 10001

#include <Zmq/Zmq.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    Context context;

    //  Socket to talk to server
    Print("Collecting updates from weather server…");
    Socket subscriber(context, ZMQ_SUB);
    subscriber.connect("tcp://localhost:5556");

    subscriber.subscribe(InpZipCode);

    //  Process 100 updates
    int update_nbr;
    long total_temp = 0;
    for (update_nbr = 0; update_nbr < 100; update_nbr++)
    {
        ZmqMsg update;
        long zipcode, temperature, relhumidity;

        subscriber.recv(update);

        string msg = update.getData();
        string msg_array[];
        StringSplit(msg, ' ', msg_array);
        zipcode = StringToInteger(msg_array[0]);
        temperature = StringToInteger(msg_array[1]);
        relhumidity = StringToInteger(msg_array[2]);
        total_temp += temperature;
    }
    PrintFormat("Average temperature for zipcode '%s' was %dF",
                InpZipCode, (int)(total_temp / update_nbr));
}
//+------------------------------------------------------------------+
