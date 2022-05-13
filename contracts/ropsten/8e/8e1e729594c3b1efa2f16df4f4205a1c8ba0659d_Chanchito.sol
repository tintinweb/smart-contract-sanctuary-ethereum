pragma solidity 0.4.24;

contract Chanchito {
    
    mapping(address => uint256) public romperTime;
    mapping(address => uint256) public balances;
    
    function crear(uint256 _delta) public {
        require(romperTime[msg.sender] == 0, 'The Chanchito existe.');
        romperTime[msg.sender] = block.timestamp + _delta;
    }
    
    function borrar() public {
        require(balances[msg.sender] == 0, 'The Chanchito tiene plata.');
        delete romperTime[msg.sender];
        delete balances[msg.sender];
    }
    
    function deposit() public payable {
        require(romperTime[msg.sender] != 0, 'The Chanchito no existe.');
        uint256 aux = balances[msg.sender] + msg.value;
        require(aux >= msg.value && aux >= balances[msg.sender], 'Overflow!');
        balances[msg.sender] = aux;
    }
    
    
    /*
        Guarda @dev! esto es toda la documentacion que vas a tener.
    */
    function romper() public returns (bool) {
        require(block.timestamp > romperTime[msg.sender], 'Nana...todavia no!');
        require(balances[msg.sender] > 0, 'No ahorraste nada');
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
        return true;
    }

}