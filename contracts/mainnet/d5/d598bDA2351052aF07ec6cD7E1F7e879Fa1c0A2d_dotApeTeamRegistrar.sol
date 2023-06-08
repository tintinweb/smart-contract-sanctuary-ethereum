/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: dotApe/implementations/namehash.sol


pragma solidity 0.8.7;

contract apeNamehash {
    function getNamehash(string memory _name) public pure returns (bytes32 namehash) {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked('ape')))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
    }

    function getNamehashSubdomain(string memory _name, string memory _subdomain) public pure returns (bytes32 namehash) {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked('ape')))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_subdomain)))
        );
    }
}
// File: dotApe/implementations/addressesImplementation.sol


pragma solidity ^0.8.7;

interface IApeAddreses {
    function owner() external view returns (address);
    function getDotApeAddress(string memory _label) external view returns (address);
}

pragma solidity ^0.8.7;

abstract contract apeAddressesImpl {
    address dotApeAddresses;

    constructor(address addresses_) {
        dotApeAddresses = addresses_;
    }

    function setAddressesImpl(address addresses_) public onlyOwner {
        dotApeAddresses = addresses_;
    }

    function owner() public view returns (address) {
        return IApeAddreses(dotApeAddresses).owner();
    }

    function getDotApeAddress(string memory _label) public view returns (address) {
        return IApeAddreses(dotApeAddresses).getDotApeAddress(_label);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyRegistrar() {
        require(msg.sender == getDotApeAddress("registrar"), "Ownable: caller is not the registrar");
        _;
    }

    modifier onlyErc721() {
        require(msg.sender == getDotApeAddress("erc721"), "Ownable: caller is not erc721");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == getDotApeAddress("team"), "Ownable: caller is not team");
        _;
    }

}
// File: dotApe/implementations/registryImplementation.sol



pragma solidity ^0.8.7;


pragma solidity ^0.8.7;

interface IApeRegistry {
    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name, uint256 expiry_) external;
    function getTokenId(bytes32 _hash) external view returns (uint256);
    function getName(uint256 _tokenId) external view returns (string memory);
    function currentSupply() external view returns (uint256);
    function nextTokenId() external view returns (uint256);
    function addOwner(address address_) external;
    function changeOwner(address address_, uint256 tokenId_) external;
    function getOwner(uint256 tokenId) external view returns (address);
    function getExpiration(uint256 tokenId) external view returns (uint256);
    function changeExpiration(uint256 tokenId, uint256 expiration_) external;
    function setPrimaryName(address address_, uint256 tokenId) external;
}

pragma solidity ^0.8.7;

abstract contract apeRegistryImpl is apeAddressesImpl {
    
    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name, uint256 expiry_) internal {
        IApeRegistry(getDotApeAddress("registry")).setRecord(_hash, _tokenId, _name, expiry_);
    }

    function getTokenId(bytes32 _hash) internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).getTokenId(_hash);
    }

    function getName(uint256 _tokenId) internal view returns (string memory) {
        return IApeRegistry(getDotApeAddress("registry")).getName(_tokenId);     
    }

    function nextTokenId() internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).nextTokenId();
    }

    function currentSupply() internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).currentSupply();
    }

    function addOwner(address address_) internal {
        IApeRegistry(getDotApeAddress("registry")).addOwner(address_);
    }

    function changeOwner(address address_, uint256 tokenId_) internal {
        IApeRegistry(getDotApeAddress("registry")).changeOwner(address_, tokenId_);
    }

    function getOwner(uint256 tokenId) internal view returns (address) {
        return IApeRegistry(getDotApeAddress("registry")).getOwner(tokenId);
    }

    function getExpiration(uint256 tokenId) internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).getExpiration(tokenId);
    }

    function changeExpiration(uint256 tokenId, uint256 expiration_) internal {
        return IApeRegistry(getDotApeAddress("registry")).changeExpiration(tokenId, expiration_);
    }

    function setPrimaryName(address address_, uint256 tokenId) internal {
        return IApeRegistry(getDotApeAddress("registry")).setPrimaryName(address_, tokenId);
    }
}
// File: dotApe/implementations/erc721Implementation.sol



pragma solidity ^0.8.7;


pragma solidity ^0.8.7;

interface IERC721 {
    function mint(address to) external;
    function transferExpired(address to, uint256 tokenId) external;
}

pragma solidity ^0.8.7;

abstract contract apeErc721Impl is apeAddressesImpl {
    
    function mint(address to) internal {
        IERC721(getDotApeAddress("erc721")).mint(to);
    }

    function transferExpired(address to, uint256 tokenId) internal {
        IERC721(getDotApeAddress("erc721")).transferExpired(to, tokenId);
    }

}
// File: dotApe/teamRegistrar.sol


pragma solidity ^0.8.7;





contract dotApeTeamRegistrar is apeErc721Impl, apeRegistryImpl, apeNamehash {

    constructor(address _address) apeAddressesImpl(_address) {}

    uint256 secondsInYears = 365 days;
    bool isContractActive = true;

    struct RegisterTeam {
        string name;
        address registrant;
        uint256 durationInYears;
    }

    event Registered(address indexed to, uint256 indexed tokenId, string indexed name, uint256 expiration);
    event Extended(address indexed owner, uint256 indexed tokenId, string indexed name, uint256 previousExpiration, uint256 newExpiration);

    function registerTeam(RegisterTeam[] memory registerParams) public onlyTeam {
        require(isContractActive, "Contract is not active");
        for(uint256 i=0; i < registerParams.length; i++) {
            _register(registerParams[i].registrant, registerParams[i].name, registerParams[i].durationInYears);
        }
    }
    
    function _register(address registrant, string memory name, uint256 durationInYears) internal returns (bool) {
        require(verifyName(name), "Name not supported");
        bytes32 namehash = getNamehash(name);
        if(!isRegistered(namehash)) {
            //mint
            mint(registrant);
            uint256 tokenId = currentSupply();
            uint256 expiration = block.timestamp + (durationInYears * secondsInYears);
            setRecord(namehash, tokenId, name, expiration);

            emit Registered(registrant, tokenId, string(abi.encodePacked(name, ".ape")), expiration);
            return true;
        } else {
            uint256 tokenId = getTokenId(namehash);
            if(isExpired(tokenId)) {
                //change owner
                transferExpired(registrant, tokenId);
                uint256 expiration = block.timestamp + (durationInYears * secondsInYears);
                changeExpiration(tokenId, expiration);

                emit Registered(registrant, tokenId, string(abi.encodePacked(name, ".ape")), expiration);
                return true;
            } else {
                return false;
            }
        }
    }

    function verifyName(string memory input) public pure returns (bool) {
        bytes memory stringBytes = bytes(input);
        
        if (stringBytes.length < 3) {
            return false; // String is less than 3 characters
        }
    
        for (uint i = 0; i < stringBytes.length; i++) {
            if (stringBytes[i] == ".") {
                return false; // String contains a period
            }
        }
        
        return true; // String is valid
    }

    function isRegistered(bytes32 namehash) public view returns (bool) {
        return getTokenId(namehash) != 0;
    }

    function isExpired(uint256 tokenId) public view returns (bool) {
        return getExpiration(tokenId) < block.timestamp && getOwner(tokenId) == getDotApeAddress("expiredVault");
    }

    function flipContractActive() public onlyOwner {
        isContractActive = !isContractActive;
    }
}