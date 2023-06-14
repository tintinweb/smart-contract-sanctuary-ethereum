/**
 *Submitted for verification at Etherscan.io on 2023-06-14
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
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/interfaces/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


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
    function getPrimaryName(address address_) external view returns (string memory);
    function getPrimaryNameTokenId(address address_) external view returns (uint256);
    function getTxtRecord(uint256 tokenId, string memory label) external view returns (string memory);
    function setTxtRecord(uint256 tokenId, string memory label, string memory record) external;
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

    function getPrimaryName(address address_) internal view returns (string memory) {
        return IApeRegistry(getDotApeAddress("registry")).getPrimaryName(address_);
    }

    function getPrimaryNameTokenId(address address_) internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).getPrimaryNameTokenId(address_);
    }

    function getTxtRecord(uint256 tokenId, string memory label) internal view returns (string memory) {
        return IApeRegistry(getDotApeAddress("registry")).getTxtRecord(tokenId, label);
    }

    function setTxtRecord(uint256 tokenId, string memory label, string memory record) internal {
        return IApeRegistry(getDotApeAddress("registry")).setTxtRecord(tokenId, label, record);
    }
}
// File: dotApe/implementations/erc721Implementation.sol



pragma solidity ^0.8.7;




pragma solidity ^0.8.7;

interface apeIERC721 {
    function mint(address to) external;
    function transferExpired(address to, uint256 tokenId) external;
}

pragma solidity ^0.8.7;

abstract contract apeErc721Impl is apeAddressesImpl {
    
    function mint(address to) internal {
        apeIERC721(getDotApeAddress("erc721")).mint(to);
    }

    function transferExpired(address to, uint256 tokenId) internal {
        apeIERC721(getDotApeAddress("erc721")).transferExpired(to, tokenId);
    }

    function totalSupply() internal view returns (uint256) {
        return IERC721Enumerable(getDotApeAddress("erc721")).totalSupply();
    }

}
// File: dotApe/presaleRegistrar.sol


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

pragma solidity >=0.6.0;

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }
}

pragma solidity 0.8.7;


abstract contract Signatures {

    struct Register {
        string name;
        address address_;
        uint256 durationInYears;
        uint256 cost;
        bool primaryName;
        bytes sig;
        uint256 sigExpiration;
    }

    struct Extend {
        uint256 tokenId;
        uint256 durationInYears;
        uint256 cost;
        bytes sig;
        uint256 sigExpiration;
    }
     
    function verifySignature(Register memory register_) public view returns(address) {
        require(block.timestamp < register_.sigExpiration, "Signature has expired");
        bytes32 message = keccak256(abi.encode(register_.name, register_.address_, register_.durationInYears, register_.cost, register_.primaryName, register_.sigExpiration));
        return recoverSigner(message, register_.sig);
    }

    function verifySignatureErc20(Register memory register_, address token) public view returns(address) {
        require(block.timestamp < register_.sigExpiration, "Signature has expired");
        bytes32 message = keccak256(abi.encode(register_.name, register_.address_, register_.durationInYears, register_.cost, token, register_.primaryName, register_.sigExpiration));
        return recoverSigner(message, register_.sig);
    }

    function verifySignatureExtend(Extend memory extend_) public view returns(address) {
        require(block.timestamp < extend_.sigExpiration, "Signature has expired");
        bytes32 message = keccak256(abi.encode(extend_.tokenId, extend_.durationInYears, extend_.cost, extend_.sigExpiration));
        return recoverSigner(message, extend_.sig);
    }

   function recoverSigner(bytes32 message, bytes memory sig)
       public
       pure
       returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
 
       return (v, r, s);
   }
}

contract dotApePublicRegistrar is apeErc721Impl, apeRegistryImpl, apeNamehash, priceOracleImpl, Signatures {

    constructor(address _address) apeAddressesImpl(_address) {
        erc20Accepted[apecoinAddress] = true;
        erc20Accepted[usdtAddress] = true;
        erc20Accepted[wethAddress] = true;
    }
    bool isContractActive = true;
    address apecoinAddress = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
    address usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping(address => bool) private erc20Accepted;
    uint256 secondsInYears = 365 days;

    struct RegisterTeam {
        string name;
        address registrant;
        uint256 durationInYears;
    }

    struct TxtRecord {
        string label;
        string record;
    }

    struct PrimaryName {
        address address_;
        uint256 tokenId;
    }

    event Registered(address indexed to, uint256 indexed tokenId, string indexed name, uint256 expiration);
    event Extended(address indexed owner, uint256 indexed tokenId, string indexed name, uint256 previousExpiration, uint256 newExpiration);

    function register(Register[] memory registerParams) public payable {
        require(isContractActive, "Contract is not active");
        require(verifyAllSignatures(registerParams), "Not signed by signer");
        require(getTotalCost(registerParams) <= msg.value, "Value sent is not correct");
        
        bool[] memory success = new bool[](registerParams.length);
        for(uint256 i=0; i < registerParams.length; i++) {
            success[i] = _register(msg.sender, registerParams[i].name, registerParams[i].durationInYears);

            if(success[i] && registerParams[i].primaryName) {
                setPrimaryName(msg.sender, getTokenId(getNamehash(registerParams[i].name)));
            }
        }
        settleRefund(registerParams, success);
    }

    function registerErc20(Register[] memory registerParams, address token) public {
        require(isContractActive, "Contract is not active");
        require(verifyAllSignaturesErc20(registerParams, token), "Not signed by signer");
        
        receiveErc20(token, msg.sender, getTotalCost(registerParams));

        bool[] memory success = new bool[](registerParams.length);
        for(uint256 i=0; i < registerParams.length; i++) {
            success[i] = _register(msg.sender, registerParams[i].name, registerParams[i].durationInYears);

            if(success[i] && registerParams[i].primaryName) {
                setPrimaryName(msg.sender, getTokenId(getNamehash(registerParams[i].name)));
            }
        }
        settleRefundErc20(registerParams, success, token);
    }

    function getTotalCost(Register[] memory registerParams) internal pure returns (uint256) {
        uint256 total = 0;
        for(uint256 i=0; i < registerParams.length; i++) {
            total = total + registerParams[i].cost;
        }
        return total;
    }

    function verifyAllSignatures(Register[] memory registerParams) internal view returns (bool) {
        for(uint256 i=0; i < registerParams.length; i++) {
            require(verifySignature(registerParams[i]) == getDotApeAddress("signer"), "Not signed by signer");
            require(registerParams[i].address_ == msg.sender, "Caller is authorized");
        }
        return true;
    }

    function verifyAllSignaturesErc20(Register[] memory registerParams, address token) internal view returns (bool) {
        for(uint256 i=0; i < registerParams.length; i++) {
            require(verifySignatureErc20(registerParams[i], token) == getDotApeAddress("signer"), "Not signed by signer");
            require(registerParams[i].address_ == msg.sender, "Caller is authorized");
        }
        return true;
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
        require(verifyAllSignaturesExtend(extendParams), "Not signed by signer");
        require(getTotalCostExtend(extendParams) <= msg.value, "Value sent is not correct");

        for(uint256 i; i < extendParams.length; i++) {
            require(getOwner(extendParams[i].tokenId) == msg.sender, "Caller not owner");
            _extend(extendParams[i].tokenId, extendParams[i].durationInYears);
        }
    }

    function getTotalCostExtend(Extend[] memory extendParams) internal pure returns (uint256) {
        uint256 total = 0;
        for(uint256 i=0; i < extendParams.length; i++) {
            total = total + extendParams[i].cost;
        }
        return total;
    }

    function verifyAllSignaturesExtend(Extend[] memory extendParams) internal view returns (bool) {
        for(uint256 i=0; i < extendParams.length; i++) {
            require(verifySignatureExtend(extendParams[i]) == getDotApeAddress("signer"), "Not signed by signer");
        }
        return true;
    }

    function extendTeam(Extend[] memory extendParams) public onlyTeam {
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

    function setPrimary(uint256 tokenId) public {
        require(getOwner(tokenId) == msg.sender, "Caller is not the owner");
        setPrimaryName(msg.sender, tokenId);
    }

    function setPrimaryTeam(PrimaryName[] memory primaryNames) public onlyTeam {
        for(uint256 i=0; i<primaryNames.length; i++) {
            setPrimaryName(primaryNames[i].address_, primaryNames[i].tokenId);
        }
    }

    function setTxtRecords(uint256 tokenId, TxtRecord[] memory txtRecords) public {
        require(isContractActive, "Contract is not active");
        require(getOwner(tokenId) == msg.sender, "Caller is not the owner");

        for(uint256 i=0; i<txtRecords.length; i++) {
            setTxtRecord(tokenId, txtRecords[i].label, txtRecords[i].record);
        }
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

            if (uint8(stringBytes[i]) >= 65 && uint8(stringBytes[i]) <= 90) {
                return false; // String contains uppercase letters
            }
        }
        
        return true; // String is valid and lowercase
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

    function settleRefund(Register[] memory registerParams, bool[] memory success) internal {
        for(uint256 i; i < registerParams.length; i++) {
            if(!success[i]) {
                payable(msg.sender).transfer(registerParams[i].cost);
            }
        }
    }

    function settleRefundErc20(Register[] memory registerParams, bool[] memory success, address erc20) internal {
        for(uint256 i; i < registerParams.length; i++) {
            if(!success[i]) {
                sendErc20(erc20, msg.sender, registerParams[i].cost);
            }
        }
    }

    function receiveErc20(address erc20, address spender, uint256 amount) internal {
        require(amount <= IERC20(erc20).allowance(spender, address(this)), "Value not allowed by caller");
        TransferHelper.safeTransferFrom(erc20, spender, address(this), amount);
    }

    function sendErc20(address erc20, address receiver, uint256 amount) internal {
        require(IERC20(erc20).balanceOf(address(this)) >= amount, "Balance of contract is less than amount");
        TransferHelper.safeTransfer(erc20, receiver, amount);
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }

    function withdrawErc20(address to, uint256 amount, address token_) public onlyOwner {
        IERC20 erc20 = IERC20(token_);
        require(amount <= erc20.balanceOf(address(this)), "Amount exceeds balance.");
        TransferHelper.safeTransfer(token_, to, amount);
    }

    function flipContractActive() public onlyOwner {
        isContractActive = !isContractActive;
    }
}