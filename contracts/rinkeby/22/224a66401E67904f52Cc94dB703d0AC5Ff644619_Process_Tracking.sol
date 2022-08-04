/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

pragma solidity ^0.8.15;


contract Process_Tracking {
    address public manager;
    mapping(address => bool) public factories;
    mapping(address => address) public processes;

    //Constructor
    constructor(){
        manager = msg.sender;
    }


    //Method
    function addFactory(address factory) public returns (address){
        require(msg.sender == manager, "Only the manager");
        factories[factory] = true;
        Process process = new Process(factory, address(this));
        processes[factory] = address(process);
        return address(process);
    }
}



contract Process{
     //Structures
    struct Information{
        uint quantity;
        string name;
        address origin;
    }

    struct Output{
        uint[] inputs;
        uint[] inputsQuantities;
        string name;
        uint quantity;
    }

    //Fields
    address public factory;
    address private process_tracking;
    mapping(uint => Information) public inputs;
    mapping(uint => Output) public outputs;
    uint private id;

    //Modifier
    modifier restricted(){
        require(msg.sender == factory, "You don't have access to this function");
        _;
    }

    modifier protected() {
        Process_Tracking master = Process_Tracking(process_tracking);
        require(master.factories(tx.origin), "You don't have access to this function");
        _;
    }


    //Constructor
    constructor(address Factory, address tracking){
        factory = Factory;
        process_tracking = tracking;
        id = 1000;
    }



    //Accessor
    function getOutputItem(uint _id) public view returns (uint[] memory, uint[] memory){
        return (outputs[_id].inputs, outputs[_id].inputsQuantities);
    }



    //Methods
    function addInput(uint _id, uint _quantity, address _origin,
    string memory _name) public protected
    {
        require(inputs[_id].quantity == 0, "This id is already used");
        inputs[_id] = Information({
            quantity: _quantity,
            name: _name,
            origin: _origin
        });
    }

    function addResource(uint _id, uint _quantity,
    string memory _name) public restricted
    {
        require(inputs[_id].quantity == 0, "This id is already used");
        inputs[_id] = Information({
            quantity: _quantity,
            name: _name,
            origin: address(this)
        });
    }

    function addOutput(uint[] memory _inputs, uint[] memory _quantities,
    uint _quantity, string memory _name) public restricted returns(uint)
    {
        require(_inputs.length == _quantities.length, "Not enougth arguments in the list");
        Output storage output = outputs[id];
        for(uint idx=0; idx <_inputs.length; idx++){
            require(inputs[_inputs[idx]].quantity >= _quantities[idx], "Not enougth quantity in the stock");
            inputs[_inputs[idx]].quantity -= _quantities[idx];
            output.inputs.push(_inputs[idx]);
            output.inputsQuantities.push(_quantities[idx]);
        }
        output.quantity = _quantity;
        output.name = _name; 
        id += 1;
        return id - 1;
    }

    function sendOutput(uint _id, uint _quantity, address _addr) public restricted{
        Output storage output = outputs[_id];
        require(output.quantity >= _quantity, "Not enougth quantity in the stock");
        output.quantity -= _quantity;
        Process(_addr).addInput(_id, _quantity, address(this), output.name);
    }
}


    /*struct Livraison{
        string transporterName;
        address receiver;
        mapping(string => uint) cargaison;
        uint expeditionDate;
        uint livraisonDate;
    }*/


    /*Livraison[] transport;

    /*function sendOutputs(string memory transporterName, string memory name,
                        uint quantity, address receiver) public restricted
    {
        Livraison storage livraison = transport.push();
        livraison.transporterName = transporterName;
        livraison.receiver = receiver;
        livraison.expeditionDate = block.timestamp;
        livraison.cargaison[name] = quantity;
    }*


    V2

pragma solidity ^0.8.15;

contract Process{
    //Structures
    struct Information{
        uint quantity;
        string name;
        address origin;
    }

    struct Output{
        uint[] inputs;
        uint[] inputsQuantities;
        string name;
        uint quantity;
    }

    //Fields
    address public factory;
    address private tracking_process;
    mapping(uint => Information) public inputs;
    mapping(uint => Output) public outputs;
    uint id;

    //Modifier
    modifier restricted(){
        require(msg.sender == factory, "You don't have access to this function");
        _;
    }

    modifier protected() {
        //Tracking_Process master = Tracking_Process(tracking_process);
        //require(master.factories(tx.origin), "You don't have access to this function");
        _;
    }


    //Constructor
    constructor(address Factory, address tracking){
        factory = Factory;
        tracking_process = tracking;
        id = 1000;
    }


    //Methods
    function addInput(uint _id, uint _quantity, address _origin,
    string memory _name) public protected{
        require(inputs[_id].quantity == 0);
        inputs[_id] = Information({
            quantity: _quantity,
            name: _name,
            origin: _origin
        });
    }

    function addResource(uint _id, uint _quantity,
    string memory _name) public restricted{
        require(inputs[_id].quantity == 0);
        inputs[_id] = Information({
            quantity: _quantity,
            name: _name,
            origin: address(this)
        });
    }

    function addOutput(uint[] memory _inputs, uint[] memory _quantities,
    uint _quantity, string memory _name) public restricted{
        require(_inputs.length == _quantities.length);
        Output storage output = outputs[id];
        for(uint idx=0; idx <_inputs.length; idx++){
            require(inputs[_inputs[idx]].quantity >= _quantities[idx]);
            inputs[_inputs[idx]].quantity -= _quantities[idx];
            output.inputs.push(_inputs[idx]);
            output.inputsQuantities.push(_quantities[idx]);
        }
        output.quantity = _quantity;
        output.name = _name; 
        id += 1;
    }

    function sendOutput(uint _id, uint _quantity, address _addr) public restricted {
        Output storage output = outputs[_id];
        require(output.quantity >= _quantity);
        output.quantity -= _quantity;
        Process(_addr).addInput(_id, _quantity, address(this), output.name);
    }

*/