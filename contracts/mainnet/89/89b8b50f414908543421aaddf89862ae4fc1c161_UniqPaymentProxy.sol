// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./SignatureVerify.sol";
import "../../utils/uniq/Ierc20.sol";
import "../../interfaces/IUniqRedeemV2.sol";

contract UniqPaymentProxy is Ownable, SignatureVerify {
    IUniqRedeemV2 internal _redeem;

    // ----- EVENTS ----- //
    event TokensRequested(
        address indexed _requester,
        address indexed _mintAddress,
        uint256[] _tokenIds,
        uint256 _bundleId
    );
    event TokensBougth(
        address indexed _mintingContractAddress,
        address indexed _sellerAddress,
        address indexed _receiver,
        uint256 _bundleId,
        uint256[] _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        uint256 _sellerFee
    );
    event Withdraw(
        address indexed _sellerAddress,
        address _tokenContractAddress,
        uint256 _amount
    );

    // ----- VARIABLES ----- //
    uint256 internal _transactionOffset;
    mapping(address => mapping(address => uint256)) internal _addressBalance;
    uint256 internal _networkId;
    mapping(bytes => bool) internal _isSignatureUsed;
    mapping(address => mapping(uint256 => bool))
        internal _tokenAlreadyRequested;
    mapping(uint256 => bool) internal _isNonceUsed;

    // ----- CONSTRUCTOR ----- //
    constructor(uint256 _pnetworkId) {
        _transactionOffset = 3 minutes;
        _networkId = _pnetworkId;
    }

    function setRedeemAddress(IUniqRedeemV2 _redeemAddress) external onlyOwner {
        _redeem = _redeemAddress;
    }

    // ----- VIEWS ----- //
    function getRedeemAddress() external view returns (address) {
        return address(_redeem);
    }

    function tokenBalanceOf(address _tokenAddress, address _address)
        external
        view
        returns (uint256)
    {
        return (_addressBalance[_tokenAddress][_address]);
    }

    // ----- MESSAGE SIGNATURE ----- //
    /// @dev not test for functions related to signature
    function getMessageHash(
        address _mintingContractAddress,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        string memory _redeemerName,
        uint256 _purpose
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _networkId,
                    _mintingContractAddress,
                    _sellerAddress,
                    _percentageForSeller,
                    _bundleId,
                    _tokenIds,
                    _price,
                    _paymnetTokenAddress,
                    _timestamp,
                    _redeemerName,
                    _purpose
                )
            );
    }

    /// @dev not test for functions related to signature
    function verifySignature(
        address _mintingContractAddress,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp,
        string memory _redeemerName,
        uint256 _purpose
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _mintingContractAddress,
            _sellerAddress,
            _percentageForSeller,
            _bundleId,
            _tokenIds,
            _price,
            _paymentTokenAddress,
            _timestamp,
            _redeemerName,
            _purpose
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    function getMessageHashRequester(
        address _mintContractAddress,
        uint256 _mintNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        address _requesterAddress
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _networkId,
                    _mintContractAddress,
                    _mintNetworkId,
                    _sellerAddress,
                    _percentageForSeller,
                    _bundleId,
                    _tokenIds,
                    _price,
                    _paymnetTokenAddress,
                    _timestamp,
                    _requesterAddress
                )
            );
    }

    function verifySignatureRequester(
        address _mintContractAddress,
        uint256 _mintNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHashRequester(
            _mintContractAddress,
            _mintNetworkId,
            _sellerAddress,
            _percentageForSeller,
            _bundleId,
            _tokenIds,
            _price,
            _paymentTokenAddress,
            _timestamp,
            msg.sender
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    function _redeemTokens(
        address _mintingContractAddress,
        uint256[] memory _tokenIds,
        string memory _redeemerName,
        uint256 _purpose
    ) internal {
        address[] memory contractAddresses = new address[](_tokenIds.length);
        uint256[] memory purposes = new uint256[](_tokenIds.length);
        string[] memory names = new string[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            contractAddresses[i] = _mintingContractAddress;
            purposes[i] = _purpose;
            names[i] = _redeemerName;
        }
        _redeem.redeemTokensAsAdmin(
            contractAddresses,
            _tokenIds,
            purposes,
            names
        );
    }

    // ----- PUBLIC METHODS ----- //
    function buyTokens(
        address _mintingContractAddress,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        address _receiver,
        bytes memory _signature,
        uint256 _timestamp,
        string memory _redeemerName,
        uint256 _purpose
    ) external payable {
        require(
            _timestamp + _transactionOffset >= block.timestamp,
            "Transaction timed out"
        );
        require(!_isSignatureUsed[_signature], "Signature already used");
        require(
            verifySignature(
                _mintingContractAddress,
                _sellerAddress,
                _percentageForSeller,
                _bundleId,
                _tokenIds,
                _priceForPackage,
                _paymentToken,
                _signature,
                _timestamp,
                _redeemerName,
                _purpose
            ),
            "Signature mismatch"
        );
        _isSignatureUsed[_signature] = true;
        uint256 sellerFee;
        if (_priceForPackage != 0) {
            if (_paymentToken == address(0)) {
                require(msg.value >= _priceForPackage, "Not enough ether");
                if (_priceForPackage < msg.value) {
                    payable(msg.sender).transfer(msg.value - _priceForPackage);
                }
                sellerFee = (_priceForPackage * _percentageForSeller) / 100;
                _addressBalance[address(0)][_sellerAddress] += sellerFee;
                _addressBalance[address(0)][
                    address(this)
                ] += (_priceForPackage - sellerFee);
            } else {
                Ierc20(_paymentToken).transferFrom(
                    msg.sender,
                    address(this),
                    _priceForPackage
                );
                sellerFee = (_priceForPackage * _percentageForSeller) / 100;
                _addressBalance[_paymentToken][_sellerAddress] += sellerFee;
                _addressBalance[_paymentToken][
                    address(this)
                ] += (_priceForPackage - sellerFee);
            }
        }
        address[] memory _receivers = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _receivers[i] = _receiver;
        }
        IUniqCollections(_mintingContractAddress).batchMintSelectedIds(
            _tokenIds,
            _receivers
        );
        if (
            _purpose != 0 && bytes(_redeemerName).length >= 2 && (address(_redeem) != address(0))
        ) {
            _redeemTokens(_mintingContractAddress, _tokenIds, _redeemerName, _purpose);
        }
        emit TokensBougth(
            _mintingContractAddress,
            _sellerAddress,
            _receiver,
            _bundleId,
            _tokenIds,
            _priceForPackage,
            _paymentToken,
            sellerFee
        );
    }

    function requestTokens(
        address _mintContractAddress,
        uint256 _mintNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(
            _timestamp + _transactionOffset >= block.timestamp,
            "Transaction timed out"
        );
        require(!_isSignatureUsed[_signature], "Signature already used");
        require(
            verifySignatureRequester(
                _mintContractAddress,
                _mintNetworkId,
                _sellerAddress,
                _percentageForSeller,
                _bundleId,
                _tokenIds,
                _priceForPackage,
                _paymentToken,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
        _isSignatureUsed[_signature] = true;
        if (_priceForPackage != 0) {
            if (_paymentToken == address(0)) {
                require(msg.value >= _priceForPackage, "Not enough ether");
                if (_priceForPackage < msg.value) {
                    payable(msg.sender).transfer(msg.value - _priceForPackage);
                }
                uint256 sellerFee = (_priceForPackage * _percentageForSeller) /
                    100;
                _addressBalance[address(0)][_sellerAddress] += sellerFee;
                _addressBalance[address(0)][
                    address(this)
                ] += (_priceForPackage - sellerFee);
            } else {
                IERC20(_paymentToken).transferFrom(
                    msg.sender,
                    address(this),
                    _priceForPackage
                );
                uint256 sellerFee = (_priceForPackage * _percentageForSeller) /
                    100;
                _addressBalance[_paymentToken][_sellerAddress] += sellerFee;
                _addressBalance[_paymentToken][
                    address(this)
                ] += (_priceForPackage - sellerFee);
            }
        }
        if(_mintNetworkId == _networkId){ 
            if(NFTContract(_mintContractAddress).owner() == address(this)){
            address[] memory _receivers = new address[](_tokenIds.length);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                _receivers[i] = msg.sender;
            }
            IUniqCollections(_mintContractAddress).batchMintSelectedIds(
                _tokenIds,
                _receivers
            );
            return();
            }
        }
        emit TokensRequested(
            msg.sender,
            _mintContractAddress,
            _tokenIds,
            _bundleId
        );
    }

    function withdraw(address _tokenAddress, uint256 _amount) external {
        if (_tokenAddress == address(0)) {
            uint256 balance = _addressBalance[_tokenAddress][msg.sender];
            require(balance >= _amount, "Amount exceed balance");
            _addressBalance[_tokenAddress][msg.sender] -= _amount;
            require(payable(msg.sender).send(_amount));
        } else {
            uint256 balance = _addressBalance[_tokenAddress][msg.sender];
            require(balance != 0, "Nothing to recover");
            _addressBalance[_tokenAddress][msg.sender] -= _amount;
            Ierc20(_tokenAddress).transfer(msg.sender, _amount);
        }
        emit Withdraw(msg.sender, _tokenAddress, _amount);
    }

    // ----- PROXY METHODS ----- //

    function pEditClaimingAddress(address _contractAddress, address _newAddress)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).editClaimingAdress(_newAddress);
    }

    function pEditRoyaltyFee(address _contractAddress, uint256 _newFee)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).editRoyaltyFee(_newFee);
    }

    function pEditTokenUri(address _contractAddress, string memory _ttokenUri)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).editTokenUri(_ttokenUri);
    }

    function pRecoverERC20(address _contractAddress, address token)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).recoverERC20(token);
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        Ierc20(token).transfer(owner(), val);
    }

    function pTransferOwnership(address _contractAddress, address newOwner)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).transferOwnership(newOwner);
    }

    function pBatchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses,
        address _contractAddress
    ) external onlyOwner {
        IUniqCollections(_contractAddress).batchMintSelectedIds(
            _ids,
            _addresses
        );
    }

    function pBatchMintSelectedIdsAndRedeem(
        uint256[] memory _ids,
        address[] memory _addresses,
        address _contractAddress,
        string[] memory _redeemerName,
        uint256 _purpose
    ) external onlyOwner {
        IUniqCollections(_contractAddress).batchMintSelectedIds(
            _ids,
            _addresses
        );
        uint256[] memory purposes = new uint256[](_ids.length);
        address[] memory contractAddresses = new address[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            purposes[i] = _purpose;
            contractAddresses[i] = _contractAddress;
        }
        _redeem.redeemTokensAsAdmin(
            contractAddresses,
            _ids,
            purposes,
            _redeemerName
        );
    }

    function pMintNextToken(address _contractAddress, address _receiver)
        external
        onlyOwner
    {
        IUniqCollections(_contractAddress).mintNextToken(_receiver);
    }

    // ----- OWNERS METHODS ----- //

    function emergencyWithdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val != 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner {
        _transactionOffset = _newOffset;
    }

    receive() external payable {}

    function emergencyWithdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAdminsETH() external onlyOwner {
        require(
            payable(msg.sender).send(_addressBalance[address(0)][address(this)])
        );
        _addressBalance[address(0)][address(this)] = 0;
    }

    function withdrawAdminsTokens(address _tokenAddress) external onlyOwner {
        uint256 balance = _addressBalance[_tokenAddress][address(this)];
        require(balance != 0, "Nothing to recover");
        _addressBalance[_tokenAddress][address(this)] = 0;
        Ierc20(_tokenAddress).transfer(msg.sender, balance);
    }
}

interface IUniqCollections {
    function editClaimingAdress(address _newAddress) external;

    function editRoyaltyFee(uint256 _newFee) external;

    function batchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses
    ) external;

    function editTokenUri(string memory _ttokenUri) external;

    function recoverERC20(address token) external;

    function transferOwnership(address newOwner) external;

    function mintNextToken(address _receiver) external;
}

interface NFTContract {
    function mintNFTTokens(
        address _requesterAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _chainId,
        bytes memory _transactionHash
    ) external;

    function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SignatureVerify{

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// we need some information from token contract
// we also need ability to transfer tokens from/to this contract
interface Ierc20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IUniqRedeem.sol";

interface IUniqRedeemV2 is IUniqRedeem {
    function redeemTokensAsAdmin(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        string[] memory _redeemerName
    ) external;

    function redeemTokenForPurposesAsAdmin(
        address _tokenContract,
        uint256 _tokenId,
        uint256[] memory _purposes,
        string memory _redeemerName
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniqRedeem {
    event Redeemed(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _redeemerAddress,
        string _redeemerName,
        uint256[] _purposes
    );

    function isTokenRedeemedForPurpose(
        address _address,
        uint256 _tokenId,
        uint256 _purpose
    ) external view returns (bool);

    function getMessageHash(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        uint256 _price,
        address _paymentTokenAddress,
        uint256 _timestamp
    ) external pure returns (bytes32);

    function redeemManyTokens(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        string memory _redeemerName,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable;

    function redeemTokenForPurposes(
        address _tokenContract,
        uint256 _tokenId,
        uint256[] memory _purposes,
        string memory _redeemerName,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable;

    function setTransactionOffset(uint256 _newOffset) external;

    function setStatusesForTokens(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        bool[] memory isRedeemed
    ) external;

    function withdrawERC20(address _address) external;

    function withdrawETH() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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