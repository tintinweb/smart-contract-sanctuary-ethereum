/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// File: evcharging.sol


    pragma  solidity  >=0.4.21  <0.6.0;

    contract  evcharging{

// PREREQUISITE  FUNCTIONS  - Set  the  system

        address  authority;
    mapping (address => EVU) public  evuList;
    mapping (address => CSO) public  csoList;
    address  public  es;
        address  public  dso;
        uint  public  drPrice;

        constructor () public { 
// Decides  who is the  authority , and can  only be runonce at the  beginning.
            authority = msg.sender; 
//used  for  functions  that  only  the  authoritycan  access  and  modify

        }


        struct  EVU {

            address  addr;
            uint  tokens;
            uint  SOC;

        }

        struct  CSO {
            address  addr;
            uint  tokens;
            uint  power; // available  power  at  charging  station
            uint  price; //price  for  using  the  charging  station

        }

        function  setDSO(address  _dso , uint  _drPrice) public{

            require(msg.sender  ==  authority);
            dso = _dso;

            drPrice = _drPrice;

        }

        function  setES(address  _es) public{
        require(msg.sender  ==  authority);
        es = _es;

        }


        function  newEVU(address  _evuAddr) payable  public{
            EVU  storage  evu = evuList[_evuAddr ];
            require(msg.sender  ==  authority);
            evu.addr = _evuAddr;
            evu.SOC = 0;
            evu.tokens = 0;
            // ev.energyDemand  =0;
            // ev.chargingTime  =0;???

        }

        function  changeTokensEvu(address  _evuAddr , uint  _tokens) public{

        require(msg.sender  ==  authority);

        evuList[_evuAddr ]. tokens  +=  _tokens;

        }
        function  newCSO(address  _csoAddr , uint  _power , uint  _price) public{
            require(msg.sender  ==  authority);
            CSO  storage  cso =csoList[_csoAddr ];
            cso.addr = _csoAddr;
            cso.power = _power;
            cso.price = _price;
            cso.tokens = 0;
        }

        function  changeTokensCso(address  _csoAddr , uint  _tokens) public{
        require(msg.sender  ==  authority);
        csoList[_csoAddr ]. tokens  +=  _tokens;

        }

        //The  charging  process

        struct  Process{

            address  evuAddr;

            address  csoAddr;

            uint  energyDemand;

            uint  chargingTime;

            uint  power;

            bool[]  schedule;

            uint[]  prices;

            uint  csoPrice;

            bool  connected;

            bool[]  settled; // whether a time -step is  settled

            int[]  drSignal;

        }

        uint  public  numCPs; // Control  which  charging  process  it is

        mapping (uint => Process) public  processes;   // Connects a charging  processto a charging  process ID, cpID

        //1.  AUTHORISATION: called  by the  EVU
        function  authorisation(address  _csoAddr) public { // request  to  charge  at acharging  station

            require(evuList[msg.sender ].addr == msg.sender); // Checks  that  the  evuis  registered  in the  system , and is the  msg.sender
            require(csoList[_csoAddr ].addr ==  _csoAddr); // Checks  that  the  cso isregistered  in the  system
            require(evuList[msg.sender ]. tokens  > 100* csoList[_csoAddr ].price);
            uint  cpID = numCPs ++; // Create a charging  process  ID
            Process  storage p = processes[cpID];
            p.evuAddr= msg.sender;
            p.csoAddr= _csoAddr;
            p.power= csoList[_csoAddr ]. power;
            p.csoPrice= csoList[_csoAddr ]. price;
            p.connected= true;
            emit  Authorised(cpID); // Notification  sent  out  that  the  chargingsession  is  authorised  with  its  cpID

        }

        event  Authorised(uint  cpID);
            //2.  SCHEDULING:

            // Data  acquisition  from  the  EVU

        function  addDemand(uint  _cpID , uint  _chargingTime , uint  _energyDemand ) public{
            Process  storage p = processes[_cpID];
            require(msg.sender  == p.evuAddr) ; //can  only be added  by the  evuitself

            p.energyDemand= _energyDemand;

            p.chargingTime= _chargingTime;

            emit  requestPrices(_cpID , _chargingTime);//event  notify  ES withcharging  time  and  cpID

        }

        event  requestPrices(uint cpID , uint  chargingTime);

        //Data  acquisition  on  prices  from  the ES

        function  addPrices(uint[]  memory  _prices , uint  _cpID) public{
        require(msg.sender  == es); //Can  only be added  by the ES  itself
        require (_prices.length  ==  processes[_cpID ]. chargingTime); //have toadd  prices  for  correct  charging  time
        Process  storage p = processes[_cpID];
        p.prices = _prices;
        emit  createSchedule(_cpID);
        //event; notify  CSO to  schedule

        }

        event  createSchedule(uint  cpID);

        // Creating  the  schedule

        function  scheduling(uint  _cpID) public{

            Process  storage p = processes[_cpID]; // STORAGE?
            require ((p.energyDemand  != 0) && (p.prices.length  != 0)); // Cannotcreate  schedule  without  necessary  data
            p.schedule = new  bool [](p.chargingTime);
            p.settled = new  bool [](p.chargingTime);
            p.drSignal = new int[](p.chargingTime);
            for (uint i = 0; i<p.chargingTime; i++){
                p.schedule[i] = true;
                p.settled[i] = false;
                p.drSignal[i] = 0;

                }

            if (p.chargingTime*p.power  > p.energyDemand){ //If more  charging  timethan  needed  for  demand

                uint t = p.chargingTime - p.energyDemand/p.power; //t=hours  notcharging (rounded  up)

                uint[]  memory  priceOrder = order_sort_array(p.prices);

                    for (uint i = 0; i<t; i++){

                        uint  temp = priceOrder[i];

                        p.schedule[temp] = false;

                        }

            }

        }

        //3.  CONTROL:
        function  control(uint  _cpID , uint  time) public{

            Process  storage p = processes[_cpID];

            require(msg.sender  == p.csoAddr); // controlled  by the  cso

            checkDRAndUpdate(_cpID , time);

            if ((p.connected  == true ) && (p.schedule[time] == true)){

            evuList[p.evuAddr ].SOC += p.power;

            }

            if ((p.connected  == false) && (p.schedule[time] == true)){

            p.schedule[time] = false; //if not  connected , but  schedule = true ,update  schedule  to false.

            }




        }

        event  AcceptedDR(uint  _cpID , uint  time);

        function  addDRsignal(uint  _cpID , uint time , int  signal) public{
            require(msg.sender  == dso);

            Process  storage p = processes[_cpID];

            if (( signal  == 1) || (signal  ==  -1)){

                p.drSignal[time] = signal;

            }

        }

        //4.  PAYMENT:

        function  payment(uint  _cpID , uint  time) public{

            Process  storage p = processes[_cpID];

            if ((p.connected  == true ) && (p.schedule[time] == true) && (p.settled[
            time] ==  false)){ //only  occur  if rules  are  met

            payES(p.evuAddr , p.prices[time]*p.power);

            }

            if (p.drSignal[time ]==2){

                payDR(p.evuAddr);

            }

            payCSO(p.evuAddr ,p.csoAddr ,p.csoPrice);

            //if  responded  to dr - dso  pays.

            p.settled[time] = true;

            if (time == p.chargingTime -1) { // disconnect  if  charging  is  finished

                p.connected = false;

            }

        }

        function  disconnect(uint  _cpID) public {

            Process  storage p = processes[_cpID];

            require(msg.sender  == p.evuAddr); //only  the  evu  can  disconnect  before charging  schedule  is  finished

            p.connected = false;

        }

        // Internal  functions:

        // Private  means it can  only be used by the  functions  in the  contract , whererules  are  followed.

        function  payCSO(address  _sender , address  _receiver , uint  amount) private{

            require (( amount  <= evuList[_sender ]. tokens), "Insufficient  balance.");

            evuList[_sender ]. tokens  -= amount;// subtract  amount  from  sender

            csoList[_receiver ]. tokens  += amount;   //add  amount  to  receiver

        }
        function  payES(address  _sender , uint  amount) private{ // amount  positive  if sending  gtokens , negative  if  receiving  tokens
            require(amount  <= evuList[_sender ]. tokens);
            evuList[_sender ]. tokens  -= amount;
        }

        function  payDR(address  _receiver) private{

            evuList[_receiver ]. tokens  +=  drPrice;

        }

        function  checkDRAndUpdate(uint  _cpID , uint  time) private{

            Process  storage p = processes[_cpID];

            while ((p.drSignal[time] == 1)&&(p.schedule[time ]== false)){

        for(uint i=time +1; i<p.chargingTime; i++){
                    if(p.schedule[i] == true){
                        p.schedule[i] = false;

                        p.schedule[time] = true;

                    p.drSignal[time] = 2;

                    emit  AcceptedDR(_cpID , time);

            break;

                    }

                }

        }

        while ((p.drSignal[time] ==  -1)&&(p.schedule[time ]== true)){

            for(uint i=time +1; i<p.chargingTime; i++){

                            if(p.schedule[i] == false){

                            p.schedule[i] = true;

                            p.schedule[time] = false;

                            p.drSignal[time] = 2;

                            emit  AcceptedDR(_cpID , time);

                break;

                            }

                        }

                }

        }
        function  order_sort_array(uint[]  memory  arr) private  pure  returns (uint[]
            memory) {

            uint l = arr.length;
            uint[]  memory  order = new  uint [](l);
            for(uint i = 0; i < l; i++) {

                order[i] = i; }

            for(uint i = 0; i < l; i++) {

                for(uint j = i+1; j < l ;j++) {

                    if(arr[i] < arr[j]) {

                        uint  temp = arr[i];
                        arr[i] = arr[j];
                        arr[j] = temp;
                        uint  temp2 = order[i];
                        order[i] = order[j];
                        order[j] = temp2;



                    }

                }

            }

        return  order;

        }

        function  getOrder(uint  _cpID) public  view  returns (uint[]  memory) {

            return(order_sort_array(processes[_cpID ]. prices));

        }

            // Functions  for  displaying  simulation  results:
        function  getProcessInfo(uint  _cpID) public  view  returns( address , address ,
            uint , uint , uint , bool[]  memory  , uint[] memory , uint , bool ,   bool[]
            memory , int[]  memory){

            Process  memory p = processes[_cpID];

            return (p.evuAddr , p.csoAddr , p.energyDemand , p.chargingTime , p.power ,
            p.schedule ,p.prices ,p.csoPrice , p.connected , p.settled , p.drSignal)
            ;
        }

        function  getEvuBalance(address  _evu) public  view  returns(uint){

            return (evuList[_evu]. tokens);

        }

        function  getSOC(address  _evu) public  view  returns(uint){

        return (evuList[_evu].SOC);

        }

        function  getCsoBalance(address  _cso) public  view  returns(uint){

            return (csoList[_cso]. tokens);

        }

        function  getAddressAuth ()  public  view  returns(address , address , address){

            return(authority , dso , es);
        }
        function  getCpID ()  public  view  returns(uint){
            return (numCPs -1);
        }
    }