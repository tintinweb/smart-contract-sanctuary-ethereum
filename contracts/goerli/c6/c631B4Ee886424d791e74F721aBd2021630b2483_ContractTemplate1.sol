/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

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
    address nftAddress;
    uint privilegeId;
}

contract ContractTemplate1 {
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    
    bytes32 constant TASKCONFIRM_TYPEHASH = 0x250cdec45eac54cbd611f9a03f4199cee6afeb43b3f5b76544e7828e24015768;
    bytes32 public DOMAIN_SEPARATOR;

    
    mapping(address => bool) supportNFT;
    
    mapping(address => uint) requiredPrivilege;
    
    IERC20 public token;
    
    mapping(address => mapping(uint => bool)) public claimRecords;
    
    mapping(address => bool) public extraTask;
    
    mapping(address => bool) public validSigner;
    
    mapping(address => uint) public nonces;
    uint public amountPerAddress;
    uint public startTime;
    uint public endTime;
    bool extraTaskVerify;
    uint public total;
    uint public claimed;
    mapping(address => uint) public depositToken;
    event SupportNFT(address nft, uint privilegeId, bool isSupported);
    event Claimed(address nft, uint tokenId, uint privilegeId, address user, uint amount);

    constructor(NftRegistration[] memory nftRegs, IERC20 _token,uint _amountPerAddress,uint _startTime, uint _endTime, uint _total,bool _extraTaskVerify) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "WNFTCampaign",
            version: '1',
            chainId: chainId,
            verifyingContract: address(this)
        }));
        uint supportNftTotal = nftRegs.length;
        for (uint i=0; i < supportNftTotal; i++) {
            supportNFT[nftRegs[i].nftAddress] = true;
            requiredPrivilege[nftRegs[i].nftAddress] = nftRegs[i].privilegeId;
            emit SupportNFT(nftRegs[i].nftAddress, nftRegs[i].privilegeId, true);
        }
        validSigner[msg.sender] = true;
        token = _token;
        amountPerAddress = _amountPerAddress;
        startTime = _startTime;
        endTime = _endTime;
        extraTaskVerify = _extraTaskVerify;
        total = _total;
    }

    function claim(address nft, uint tokenId, bytes memory extraVerify) external {
        require(getBlockTimestamp() >= startTime, "campaign not started");
        require(getBlockTimestamp() <= endTime, "campaign has ended");
        require(supportNFT[nft], "nft not supported");
        require(!claimRecords[nft][tokenId], "already claimed");
        require(claimed < total, "quota reached");
        require(IERC5496(nft).hasPrivilege(tokenId, requiredPrivilege[nft], msg.sender), "no privileges");
        if (extraTaskVerify) {
            (bool success, bytes memory returndata) = address(this).call(extraVerify);
            _verifyCallResult(success, returndata, "(unknown)");
            require(extraTask[msg.sender], "extra task not completed");
        }
        claimRecords[nft][tokenId] = true;
        claimed += 1;
        token.transfer(msg.sender, amountPerAddress);
        emit Claimed(nft, tokenId, requiredPrivilege[nft], msg.sender, amountPerAddress);
    }

    function taskConfirm(address account, uint nonce, uint deadline, bytes32 r, bytes32 s, uint8 v) external {
        bytes32 txInputHash = keccak256(abi.encode(TASKCONFIRM_TYPEHASH, account, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            txInputHash
        ));
        address signatory = ecrecover(digest, v, r, s);
        require(validSigner[signatory], "signature not match");
        require(getBlockTimestamp() <= deadline, "signature expired");
        require(nonces[account]++ == nonce, "nonce error");
        extraTask[account] = true;
    }


    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
        token.transferFrom(msg.sender, address(this), amount);
        depositToken[msg.sender] += amount;
    }

    function withdrawToken(uint amount) external {
        require(getBlockTimestamp() > endTime, "campaign not ended");
        
        require(depositToken[msg.sender] >= amount, "amount too large");
        depositToken[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    
    
    
    
    
    
}