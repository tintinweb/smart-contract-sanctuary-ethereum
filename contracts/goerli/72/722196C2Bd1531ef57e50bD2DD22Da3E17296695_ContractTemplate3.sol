/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}





            

pragma solidity ^0.8.0;

interface IERC5496 {
    event PrivilegeAssigned(uint tokenId, uint privId, address user, uint64 expires);
    event PrivilegeTransfer(uint tokenId, uint privId, address from, address to);
    event PrivilegeTotalChanged(uint newTotal, uint oldTotal);
    function setPrivilege(uint256 tokenId, uint privId, address user, uint64 expires) external;
    function hasPrivilege(uint256 tokenId, uint256 privId, address user) external view returns(bool);
    function privilegeExpires(uint256 tokenId, uint256 privId) external view returns(uint256);
}




            



pragma solidity ^0.8.0;




abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





            



pragma solidity ^0.8.0;


interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}





pragma solidity ^0.8.0;





struct EIP712Domain {
    string  name;
    string  version;
    uint256 chainId;
    address verifyingContract;
}

struct NftRegistration{
    address wnftAddress;
    uint privilegeId;
}

contract ContractTemplate3 is Ownable{
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    
    bytes32 constant TASKCONFIRM_TYPEHASH = 0x250cdec45eac54cbd611f9a03f4199cee6afeb43b3f5b76544e7828e24015768;
    bytes32 public DOMAIN_SEPARATOR;

    
    mapping(address => bool) supportNFT;
    
    mapping(address => uint) requiredPrivilege;
    
    IERC20 public sellToken;
    IERC20 public payToken;
    address public eventOwner;
    
    mapping(address => mapping(uint => bool)) public exchangeRecords;
    uint public amountPerAddress;
    uint public amountPerOrder;
    uint public startTime;
    uint public endTime;
    mapping(address => uint) public depositToken;
    event SupportNFT(address wnft, uint privilegeId, bool isSupported);
    event Fulfillment(address wnft, uint tokenId, uint privilegeId, address indexed user, uint payAmount, uint gainAmount);
    event EventOwnerChange(address newOwner, address oldOwner);

    constructor(NftRegistration[] memory wnftRegs, IERC20 _sellToken, IERC20 _payToken, address _eventOwner,uint _amountPerAddress,uint _amountPerOrder,uint _startTime, uint _endTime) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "WNFT.one",
            version: '1',
            chainId: chainId,
            verifyingContract: address(this)
        }));
        uint supportNftTotal = wnftRegs.length;
        for (uint i=0; i < supportNftTotal; i++) {
            supportNFT[wnftRegs[i].wnftAddress] = true;
            requiredPrivilege[wnftRegs[i].wnftAddress] = wnftRegs[i].privilegeId;
            emit SupportNFT(wnftRegs[i].wnftAddress, wnftRegs[i].privilegeId, true);
        }
        sellToken = _sellToken;
        payToken = _payToken;
        eventOwner = _eventOwner;
        amountPerAddress = _amountPerAddress;
        amountPerOrder = _amountPerOrder;
        startTime = _startTime;
        endTime = _endTime;
    }

    function setEventOwner(address newOwner) external {
        emit EventOwnerChange(newOwner, eventOwner);
        eventOwner = newOwner;
    }

    function fulfillment(address wnft, uint tokenId) external {
        require(getBlockTimestamp() >= startTime, "campaign not started");
        require(getBlockTimestamp() <= endTime, "campaign has ended");
        require(supportNFT[wnft], "wnft not supported");
        require(!exchangeRecords[wnft][tokenId], "already claimed");
        require(IERC5496(wnft).hasPrivilege(tokenId, requiredPrivilege[wnft], msg.sender), "no privileges");
        
        exchangeRecords[wnft][tokenId] = true;
        payToken.transferFrom(msg.sender, address(this), amountPerOrder);
        sellToken.transfer(msg.sender, amountPerAddress);
        emit Fulfillment(wnft, tokenId, requiredPrivilege[wnft], msg.sender, amountPerOrder, amountPerAddress);
    }

    function getBlockTimestamp() internal view returns (uint) {
        
        return block.timestamp;
    }

    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function deposit(uint amount) external {
        sellToken.transferFrom(msg.sender, address(this), amount);
        depositToken[msg.sender] += amount;
    }

    function withdrawToken(uint amount) external {
        require(getBlockTimestamp() > endTime, "campaign not ended");
        
        require(depositToken[msg.sender] >= amount, "amount too large");
        depositToken[msg.sender] -= amount;
        sellToken.transfer(msg.sender, amount);
    }

    function withdrawPaid() external {
        require(getBlockTimestamp() > endTime, "campaign not ended");
        require(msg.sender == eventOwner, "not owner");
        uint balance = payToken.balanceOf(address(this));
        payToken.transfer(eventOwner, balance);
    }
}