/**
 *Submitted for verification at Etherscan.io on 2023-06-11
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
// File: dotApe/registrar.sol


pragma solidity ^0.8.7;





pragma solidity ^0.8.0;

interface priceOracle {
    function getCost(string memory name, uint256 durationInYears) external view returns (uint256);
    function getCostUsd(string memory name, uint256 durationInYears) external view returns (uint256);
    function getCostApecoin(string memory name, uint256 durationInYears) external view returns (uint256);

}

abstract contract priceOracleImpl is apeAddressesImpl {

    function getCost(string memory name, uint256 durationInYears) public view returns (uint256) {
        return priceOracle(getDotApeAddress("priceOracle")).getCost(name, durationInYears);
    }

    function getCostUsd(string memory name, uint256 durationInYears) public view returns (uint256) {
        return priceOracle(getDotApeAddress("priceOracle")).getCostUsd(name, durationInYears);
    }

    function getCostApecoin(string memory name, uint256 durationInYears) public view returns (uint256) {
        return priceOracle(getDotApeAddress("priceOracle")).getCostApecoin(name, durationInYears);
    }
}

contract dotApePublicRegistrar is apeErc721Impl, apeRegistryImpl, apeNamehash, priceOracleImpl {

    constructor(address _address) apeAddressesImpl(_address) {
        erc20Accepted[apecoinAddress] = true;
        erc20Accepted[usdtAddress] = true;
        erc20Accepted[wethAddress] = true;
    }
    bool isContractActive = false;
    address apecoinAddress = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
    address usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping(address => bool) private erc20Accepted;
    uint256 secondsInYears = 365 days;

    struct Register {
        string name;
        uint256 durationInYears;
    }

    struct RegisterTeam {
        string name;
        address registrant;
        uint256 durationInYears;
    }

    struct Extend {
        uint256 tokenId;
        uint256 durationInYears;
    }

    event Registered(address indexed to, uint256 indexed tokenId, string indexed name, uint256 expiration);
    event Extended(address indexed owner, uint256 indexed tokenId, string indexed name, uint256 previousExpiration, uint256 newExpiration);

    function register(string memory name, uint256 durationInYears, bool primaryName) public payable {
        require(isContractActive, "Contract is not active");
        require(getCost(name, durationInYears) <= msg.value, "Value sent is not correct");

        bool success = _register(msg.sender, name, durationInYears);
        settleRefund(name, durationInYears, success);

        if(primaryName) {
            setPrimaryName(msg.sender, getTokenId(getNamehash(name)));
        }
    }

    function registerErc20(string memory name, uint256 durationInYears, address erc20, bool primaryName) public {
        require(isContractActive, "Contract is not active");
        require(erc20Accepted[erc20], "Erc20 not accepted");

        receiveErc20(erc20, msg.sender, getCostErc20(name, durationInYears, erc20));

        bool success = _register(msg.sender, name, durationInYears);

        settleRefundErc20(name, durationInYears, success, erc20);

        if(primaryName) {
            setPrimaryName(msg.sender, getTokenId(getNamehash(name)));
        }
    }
    
    function registerBatch(Register[] memory registerParams) public payable {
        require(isContractActive, "Contract is not active");
        require(getTotalCost(registerParams) <= msg.value, "Value sent is not correct");

        bool[] memory success = new bool[](registerParams.length);
        for(uint256 i=0; i < registerParams.length; i++) {
            success[i] = _register(msg.sender, registerParams[i].name, registerParams[i].durationInYears);
        }
        settleRefundBatch(registerParams, success);
    }

    function registerErc20Batch(Register[] memory registerParams, address erc20) public {
        require(isContractActive, "Contract is not active");
        require(erc20Accepted[erc20], "Erc20 not accepted");

        receiveErc20(erc20, msg.sender, getTotalCostErc20(registerParams, erc20));

        bool[] memory success = new bool[](registerParams.length);
        for(uint256 i=0; i < registerParams.length; i++) {
            success[i] = _register(msg.sender, registerParams[i].name, registerParams[i].durationInYears);
        }

        settleRefundErc20Batch(registerParams, success, erc20);
    }

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

    function extend(Extend[] memory extendParams) public payable {
        require(isContractActive, "Contract is not active");
        Register[] memory registerParams = new Register[](extendParams.length);
        for(uint256 i=0; i < extendParams.length; i++) {
            registerParams[i] = Register(getName(extendParams[i].tokenId), extendParams[i].durationInYears);
        }
        require(getTotalCost(registerParams) <= msg.value, "Value sent is not correct");

        for(uint256 i; i < extendParams.length; i++) {
            require(getOwner(extendParams[i].tokenId) == msg.sender, "Caller not owner");
            _extend(extendParams[i].tokenId, extendParams[i].durationInYears);
        }
    }

    function extendTeam(Extend[] memory extendParams) public payable {
        require(isContractActive, "Contract is not active");
        for(uint256 i; i < extendParams.length; i++) {
            _extend(extendParams[i].tokenId, extendParams[i].durationInYears);
        }
    }

    function _extend(uint256 tokenId, uint256 durationInYears) internal {
        require(tokenId <= currentSupply() && tokenId != 0, "TokenId not registered");
        require(!isExpired(tokenId), "TokenId is expired");

        uint256 oldExpiration = getExpiration(tokenId);
        uint256 newExpiration = getExpiration(tokenId) + (durationInYears * secondsInYears);
        changeExpiration(tokenId, newExpiration);

        emit Extended(getOwner(tokenId), tokenId, string(abi.encodePacked(getName(tokenId), ".ape")), oldExpiration, newExpiration);
    }

    function verifyName(string memory input) public pure returns (bool) {
        bytes memory stringBytes = bytes(input);
        
        if (stringBytes.length < 3) {
            return false; // String is less than 3 characters
        }

        for (uint i = 0; i < stringBytes.length; i++) {
            if (stringBytes[i] == "." || stringBytes[i] == " ") {
                return false; // String contains a period or space
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

    function isAvailable(string memory name) public view returns (bool) {
        bytes32 namehash = getNamehash(name);
        if(isRegistered(namehash)) {
            uint256 tokenId = getTokenId(namehash);
            if(isExpired(tokenId)) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getTotalCost(Register[] memory registerParams) internal view returns (uint256) {
        uint256 cost;
        for(uint256 i=0; i < registerParams.length; i++) {
            cost = cost + getCost(registerParams[i].name, registerParams[i].durationInYears);
        }
        return cost;
    }

    function getCostErc20(string memory name, uint256 durationInYears, address erc20) internal view returns (uint256) {
        if(erc20 == usdtAddress) {
            return getCostUsd(name, durationInYears);
        } else if(erc20 == apecoinAddress) {
            return getCostApecoin(name, durationInYears);
        } else if(erc20 == wethAddress) {
            return getCost(name, durationInYears);
        } else {
            revert("erc20 not supported");
        }
    }

    function getTotalCostErc20(Register[] memory registerParams, address erc20) internal view returns (uint256) {
        uint256 cost;
        for(uint256 i=0; i < registerParams.length; i++) {
            cost = cost + getCostErc20(registerParams[i].name, registerParams[i].durationInYears, erc20);
        }
        return cost;
    }

    function settleRefund(string memory name, uint256 durationInYears, bool success) internal {
        if(!success) {
            uint256 amount = getCost(name, durationInYears);
            payable(msg.sender).transfer(amount);
        }
    }

    function settleRefundBatch(Register[] memory registerParams, bool[] memory success) internal {
        for(uint256 i; i < registerParams.length; i++) {
            settleRefund(registerParams[i].name, registerParams[i].durationInYears, success[i]);
        }
    }


    function settleRefundErc20(string memory name, uint256 durationInYears, bool success, address erc20) internal {
        if(!success) {
            uint256 amount = getCostErc20(name, durationInYears, erc20);
            payable(msg.sender).transfer(amount);
        }
    }

    function settleRefundErc20Batch(Register[] memory registerParams, bool[] memory success, address erc20) internal {

        for(uint256 i; i < registerParams.length; i++) {
            settleRefundErc20(registerParams[i].name, registerParams[i].durationInYears, success[i], erc20);
        }
    }

    function receiveErc20(address erc20, address spender, uint256 amount) internal {
        require(amount <= IERC20(erc20).allowance(spender, address(this)), "Value not allowed by caller");
        IERC20(erc20).transferFrom(spender, address(this), amount);
    }

    function sendErc20(address erc20, address receiver, uint256 amount) internal {
        require(IERC20(erc20).balanceOf(address(this)) >= amount, "Balance of contract is less than amount");
        IERC20(erc20).transfer(receiver, amount);
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }

    function withdrawErc20(address to, uint256 amount, address token_) public onlyOwner {
        IERC20 erc20 = IERC20(token_);
        require(amount <= erc20.balanceOf(address(this)), "Amount exceeds balance.");
        IERC20(erc20).transfer(to, amount);
    }

    function flipContractActive() public onlyOwner {
        isContractActive = !isContractActive;
    }
}