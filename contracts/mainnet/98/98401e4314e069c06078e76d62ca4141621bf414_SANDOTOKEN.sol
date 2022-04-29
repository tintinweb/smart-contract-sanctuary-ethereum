//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SANDOSecurity.sol";

contract SANDOTOKEN is ERC20, Ownable, AccessControl, SANDOSecurity {
    ERC20 private token;
    address public _token;
    using Strings for string;
    bool private SocketPlug = false;
    /*Fix total Supply and disabled burn token.*/
    uint256 public constant _MAX_SUPPLY = uint256(100000000000000 ether);
    uint256 private decimal=10**18;
    address public _owner;
    bool private locked = false;

    string[11] public strstage=["Free Stage.","Airdrop","Seed","PrivateSale","ICO","DEX","CEX","Marketing","Pool Liquidity","Founder","Reserve"];
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
 
    _mint(msg.sender, _MAX_SUPPLY);
    _owner = msg.sender;
    _token = address(this);

    }

    function gettoken() private view returns(address){
      return address(this);  
    }

    //Setting 
    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
    }

    //Proxy Socket Motherboard Feture 
    mapping(uint => address) public socket_mapAddress;

    /*Set struct mapping data of socket*/
    struct SocketMemory {
        bool status;
        bytes data;
    }

    mapping(uint256 => SocketMemory) public socket_memory;

    function socket_setSocket(uint _socketID, address _smartContractAddress) external onlyOwner Pauseable {

        socket_mapAddress[_socketID] = _smartContractAddress;
    }

    modifier socket_pushMemory(uint256 _socketID, bool _status, bytes memory _data)  {
        _;
        socket_memory[_socketID] = SocketMemory(_status,_data);
        
    }

    function socket_removeSocket(uint _socketID) external onlyOwner Pauseable {
        delete socket_mapAddress[_socketID];
    }

    function socket_getfunction(uint _socketID, string memory _functionName) external Pauseable returns(bool, bytes memory){
        address _contract = socket_mapAddress[_socketID];
        uint str = bytes(_functionName).length; 
        require(_contract != address(0x0), "Smart Contract not found..");
        require(str != 0, "Function not found..");

        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature(_functionName)
        );
        return (success,data); 
    }

    function convertBytestoUint256(bytes memory _bytes) external pure returns(string memory){
        return string(abi.encodePacked(true, _bytes));//abi.encodePacked(uint256(_bytes));
    }

//    function socket_callWithInstance(address payable _t,string memory strategyId, string memory functionName,address a, uint256 b) public payable returns(uint256) {
    function socket_delegatecallfunction_address_uint256(uint _socketID, string memory _functionName,address a, uint256 b) public payable returns(uint256) {
        address _contract = socket_mapAddress[_socketID];
        uint str = bytes(_functionName).length; 
        bool success = false;
        bytes memory data;
        require(_contract != address(0x0), "Strategy not found..");
        require(str != 0, "Function not found..");
        (success, data) = _contract.delegatecall(
            abi.encodeWithSignature(string(abi.encodePacked(_functionName,"(", a , ",", b ,")")))
        );
        uint256 c = abi.decode(data, (uint256));
        return c;
    }


    function socket_callWithEncodeSignature(address _t,string memory _functionName, uint a, uint b) public returns(uint) {
       bytes memory data = abi.encodeWithSignature(string(abi.encodePacked(_functionName,"(", a , ",", b ,")")));
        (bool success, bytes memory returnData) = _t.call(data);
        require(success);
        uint c = abi.decode(returnData, (uint));
        return c;
    }

    /*
       Call focus by SocketID and return all data of contract
       0. socket_mapAddress to select is not address(0x0) or is not empty address 
       1. Set select SocketID 
       2. Call Function getData of delegate socket selected
       3. automatic call function socket_delegate with _selectSocketID and check _selectSocketID > -1 
       4. fallback socket_delegate(_selectSocketID) and return data of socket_mapAddress[_socketID]
    */
    uint private _selectSocketID;
    event selectedSocketID(string remark,uint _socketID,string details); 
    event abiData(SocketMemory _data);

    function socket_getdelegate(uint _socketID) external Pauseable virtual {
        require(_socketID>=0,"SocketID is not found..");
        _selectSocketID = _socketID;
        socket_delegate();
        //emit selectedSocketID("Socket:",_selectSocketID," selected.");
    }

    function socket_delegate() Pauseable noReentrant internal virtual {
        address _contract = socket_mapAddress[_selectSocketID];
        assembly {
            // calldatacopy(t, f, s)
            // copy s bytes from calldata at position f to mem at position t
            calldatacopy(0, 0, calldatasize())

            // delegatecall(g, a, in, insize, out, outsize)
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error and 1 on success
            let result := delegatecall(gas(), _contract, 0, calldatasize(), 0, 0)

            // returndatacopy(t, f, s)
            // copy s bytes from returndata at position f to mem at position t
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // revert(p, s)
                // end execution, revert state changes, return data mem[p…(p+s))
                
                revert(0, returndatasize())
                
            }
            default {
                // return(p, s)
                // end execution, return data mem[p…(p+s))
                
                return(0, returndatasize())
            }

        }
        
    }

    event ValueReceived(address user, uint amount);

    /*
        Protect Reentrancy Attacks check and clear value of request
        use modifier noReentrant()
        before transfer values to msg.sender keep values to temporary variable 
        immediately is done and set values = 0 

    */
    
    event OwnerWithdraw(string remark,uint256 amount);
    modifier noReentrant() {
        require(!locked,"The list is not complete. please wait a moment.");
        locked = true; //before use function, set status locked is true.
        _;
        //locked = false; //after use function is finish, set status locked is false.

    }

    function Withdraw_OwnerAll() payable public Pauseable onlyOwner noReentrant{
      payable(msg.sender).transfer(address(this).balance);
      locked = false; //after use function is finish, set status locked is false.
      emit OwnerWithdraw("Owner is withdraw", address(this).balance);
    }


    fallback() external payable {
        emit ValueReceived(msg.sender, msg.value);
        /*if(SocketPlug!=false){
            socket_delegate();
            
        }*/
        //emit abiData(SocketMemory(socket_delegate()));
    }

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    function bytesToString(bytes memory byteCode) public pure returns(string memory stringData)
    {
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;

        uint cycles = byteCode.length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }

        stringData = new string(requiredAlloc);

        //copy data in 32 byte blocks
        assembly {
            let cycle := 0

            for
            {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20)   //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

    //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
        }
    }

}