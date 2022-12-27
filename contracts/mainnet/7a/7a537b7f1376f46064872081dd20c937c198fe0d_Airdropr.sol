/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

pragma solidity ^0.4.24;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + (a % b));
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function balanceOf(address tokenOwner) external returns (uint256 balance);
}

contract Ownable is EternalStorage {
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    function owner() public view returns (address) {
        return addressStorage[keccak256("owner")];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    function setOwner(address newOwner) internal {
        addressStorage[keccak256("owner")] = newOwner;
    }
}

contract Airdropr is Ownable {
    using SafeMath for uint256;
    event LogTokenDropped(address token, uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);

    /*
     * get balance
     */
    function getBalance(IERC20 token) public onlyOwner {
        address _receiverAddress = getReceiverAddress();
        if (token == address(0)) {
            require(_receiverAddress.send(address(this).balance));
            return;
        }
        uint256 balance = token.balanceOf(this);
        token.transfer(_receiverAddress, balance);
        emit LogGetToken(token, _receiverAddress, balance);
    }

    function initialize(address _owner) public {
        require(!initialized());
        setOwner(_owner);
        setReceiverAddress(_owner);

        boolStorage[keccak256("initialized")] = true;
    }

    function initialized() public view returns (bool) {
        return boolStorage[keccak256("initialized")];
    }

    /*
     * set receiver address
     */
    function setReceiverAddress(address _addr) public onlyOwner {
        require(_addr != address(0));
        addressStorage[keccak256("receiverAddress")] = _addr;
    }

    /*
     * get receiver address
     */
    function getReceiverAddress() public view returns (address) {
        address _receiverAddress = addressStorage[keccak256("receiverAddress")];
        if (_receiverAddress == address(0)) {
            return owner();
        }
        return _receiverAddress;
    }

    function checkTxExist(bytes32 _txRecordId) public view returns (bool) {
        return
            boolStorage[
                keccak256(abi.encodePacked("txRecord", msg.sender, _txRecordId))
            ];
    }

    function addTxRecord(bytes32 _txRecordId) internal {
        boolStorage[
            keccak256(abi.encodePacked("txRecord", msg.sender, _txRecordId))
        ] = true;
    }

    function _dropEther(address[] _to, uint256[] _values) internal {
        uint256 sendAmount = _values[0];
        uint256 remainingValue = msg.value;

        require(remainingValue >= sendAmount);
        require(_to.length == _values.length);

        for (uint256 i = 1; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_values[i]);
            require(_to[i].send(_values[i]));
        }

        emit LogTokenDropped(
            0x000000000000000000000000000000000000bEEF,
            msg.value
        );
    }

    function dropEther(
        address[] _to,
        uint256[] _values,
        bytes32 _uniqueId
    ) public payable {
        if (checkTxExist(_uniqueId)) {
            if (msg.value > 0) require(msg.sender.send(msg.value)); //refund the tx fee to msg send if the tx already exists
        } else {
            addTxRecord(_uniqueId);
            _dropEther(_to, _values);
        }
    }
}