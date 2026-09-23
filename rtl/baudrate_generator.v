
module baudrate_generator(input clock,reset,output reg enb_tx,enb_rx

    );
    parameter clk_freq = 100000000; // SYSTEM CLOCK FREQUENCY
    parameter baud_rate = 9600; //REQUIRED BAUD RATE
    reg [15:0] counter_tx; //REGISTER FOR CREATING THE SENDER CLOCK
    reg [15:0] counter_rx; // REGISTER FOR CREATING THE RECIEVER CLOCK

    parameter divisor_tx = clk_freq/baud_rate; //PRESCALAR OF SENDER
    parameter divisor_rx = clk_freq/(16 *baud_rate);    //PRESCALAR OF RECIEVER
   
    
            
    //SENDER CLOCK GENERATION LOGIC
    
    always@(posedge clock)
        begin
        
            if(reset)
                begin
                    counter_tx <= 0;
                    enb_tx <= 0;
                    enb_rx <= 0;
                 end
       //FOR 10,416 CLOCK CYCLES OF SYSTEM CLOCK 1 CLOCK CYCLE IS GENERATED
                 
            else if(counter_tx == divisor_tx - 1)
                begin
                    enb_tx <= 1;
                    counter_tx <= 0;
                    
                 end
              else
                begin
                   counter_tx <= counter_tx + 1'b1;
                   enb_tx <= 0;
                    
               end
     end
     
     
    //LOGIC FOR RECIEVER CLOCK
      
        always@(posedge clock)
            begin
            
                if(reset)
                    begin
                        counter_rx <= 0;
                     end
   
   //FOR GENERATING SENDER CLOCK
                     
                else if(counter_rx == divisor_rx - 1)
                    begin
                        counter_rx <= 0;
                        enb_rx <= 1;
                        
                     end
                  else
                    begin
                        counter_rx <= counter_rx + 1;
                        enb_rx <= 0;
                        
                   end
         end
     
            
    
    
    
    
endmodule
