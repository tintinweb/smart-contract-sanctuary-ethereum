// SPDX-License-Identifier: Apache 2.0

pragma solidity =0.8.17;

import "./MasterToken.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./EthTokenReciever.sol";

/**
 * Provides functionality of the HASHI bridge
 */
contract Bridge is EthTokenReciever {
    using SafeERC20 for IERC20;

    bool internal initialized_;
    bool internal preparedForMigration_;

    mapping(address => bool) public isPeer;
    uint256 public peersCount;

    /** Substrate proofs used */
    mapping(bytes32 => bool) public used;
    mapping(address => bool) public _uniqueAddresses;

    /** White list of ERC-20 ethereum native tokens */
    mapping(address => bool) public acceptedEthTokens;

    /** White lists of ERC-20 SORA native tokens
     * We use several representations of the white list for optimisation purposes.
     */
    mapping(bytes32 => address) public _sidechainTokens;
    mapping(address => bytes32) public _sidechainTokensByAddress;
    address[] public _sidechainTokenAddressArray;

    /**
     * For XOR and VAL use old token contracts, created for SORA 1 bridge.
     * Also for XOR and VAL transfers from SORA 2 to Ethereum old bridges will be used.
     */
    address public immutable _addressVAL;
    address public immutable _addressXOR;
    /** EVM netowrk ID */
    bytes32 public immutable _networkId;

    event Withdrawal(bytes32 txHash);
    event Deposit(
        bytes32 destination,
        uint256 amount,
        address token,
        bytes32 sidechainAsset
    );
    event ChangePeers(address peerId, bool removal);
    event PreparedForMigration();
    event Migrated(address to);

    /**
     * Constructor.
     * @param initialPeers - list of initial bridge validators on substrate side.
     * @param addressVAL address of VAL token Contract
     * @param addressXOR address of XOR token Contract
     * @param networkId id of current EvM network used for bridge purpose.
     */
    constructor(
        address[] memory initialPeers,
        address[] memory sidechainTokenAddresses,
        bytes32[] memory sidechainAssetIds,
        address[] memory erc20Addresses,
        address addressVAL,
        address addressXOR,
        bytes32 networkId
    ) {
        require(
            sidechainAssetIds.length == sidechainTokenAddresses.length,
            "Length mismatch"
        );

        for (uint256 i; i < initialPeers.length; i++) {
            addPeer(initialPeers[i]);
        }
        _addressXOR = addressXOR;
        _addressVAL = addressVAL;
        _networkId = networkId;
        initialized_ = true;

        acceptedEthTokens[addressXOR] = true;
        acceptedEthTokens[addressVAL] = true;

        for (uint256 i; i < sidechainTokenAddresses.length; i++) {
            address tokenAddress = sidechainTokenAddresses[i];
            bytes32 assetId = sidechainAssetIds[i];
            _sidechainTokens[assetId] = tokenAddress;
            _sidechainTokensByAddress[tokenAddress] = assetId;
            _sidechainTokenAddressArray.push(tokenAddress);
        }
        uint256 erc20TokensCount = erc20Addresses.length;
        for (uint256 i; i < erc20TokensCount; i++) {
            acceptedEthTokens[erc20Addresses[i]] = true;
        }
    }

    modifier shouldBeInitialized() {
        require(
            initialized_ == true,
            "Contract should be initialized to use this function"
        );
        _;
    }

    modifier shouldNotBePreparedForMigration() {
        require(
            preparedForMigration_ == false,
            "Contract should not be prepared for migration to use this function"
        );
        _;
    }

    modifier shouldBePreparedForMigration() {
        require(
            preparedForMigration_ == true,
            "Contract should be prepared for migration to use this function"
        );
        _;
    }

    fallback() external {
        revert();
    }

    receive() external payable {
        revert();
    }

    /*
    Used only for migration
    */
    function receivePayment() external payable override {}

    /**
     * Adds new token to whitelist.
     * Token should not been already added.
     *
     * @param newToken new token contract address
     * @param ticker token ticker (symbol)
     * @param name token title
     * @param decimals count of token decimal places
     * @param txHash transaction hash from sidechain
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function addEthNativeToken(
        address newToken,
        string memory ticker,
        string memory name,
        uint8 decimals,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized {
        require(used[txHash] == false, "txHash already used");
        require(
            acceptedEthTokens[newToken] == false,
            "ERC20 token is not whitelisted"
        );
        require(
            checkSignatures(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        newToken,
                        ticker,
                        name,
                        decimals,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;
        acceptedEthTokens[newToken] = true;
    }

    /**
     * Preparations for migration to new Bridge contract
     *
     * @param salt unique data used for signature
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function prepareForMigration(
        bytes32 salt,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized shouldNotBePreparedForMigration {
        require(used[salt] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encodePacked(
                        "prepareMigration",
                        address(this),
                        salt,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[salt] = true;
        preparedForMigration_ = true;
        emit PreparedForMigration();
    }

    /**
     * Shutdown this contract and migrate tokens ownership to the new contract.
     *
     * @param salt unique data used for signature generation
     * @param newContractAddress address of the new bridge contract
     * @param erc20nativeTokens list of ERC20 tokens with non zero balances for this contract. Can be taken from substrate bridge peers.
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function shutDownAndMigrate(
        bytes32 salt,
        address payable newContractAddress,
        address[] calldata erc20nativeTokens,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized shouldBePreparedForMigration {
        require(used[salt] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        newContractAddress,
                        salt,
                        erc20nativeTokens,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[salt] = true;
        uint256 sidechainTokensCount = _sidechainTokenAddressArray.length;
        for (uint256 i; i < sidechainTokensCount; i++) {
            Ownable token = Ownable(_sidechainTokenAddressArray[i]);
            token.transferOwnership(newContractAddress);
        }
        uint256 erc20nativeTokensCount = erc20nativeTokens.length;
        for (uint256 i; i < erc20nativeTokensCount; i++) {
            IERC20 token = IERC20(erc20nativeTokens[i]);
            token.safeTransfer(
                newContractAddress,
                token.balanceOf(address(this))
            );
        }
        EthTokenReciever(newContractAddress).receivePayment{
            value: address(this).balance
        }();
        initialized_ = false;
        emit Migrated(newContractAddress);
    }

    /**
     * Add new token from sidechain to the bridge white list.
     *
     * @param name token title
     * @param symbol token symbol
     * @param decimals number of decimals
     * @param sidechainAssetId token id on the sidechain
     * @param txHash sidechain transaction hash
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function addNewSidechainToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes32 sidechainAssetId,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized {
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        name,
                        symbol,
                        decimals,
                        sidechainAssetId,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;
        // Create new instance of the token
        MasterToken tokenInstance = new MasterToken(
            name,
            symbol,
            decimals,
            address(this),
            0,
            sidechainAssetId
        );
        address tokenAddress = address(tokenInstance);
        _sidechainTokens[sidechainAssetId] = tokenAddress;
        _sidechainTokensByAddress[tokenAddress] = sidechainAssetId;
        _sidechainTokenAddressArray.push(tokenAddress);
    }

    /**
     * Send Ethereum to sidechain.
     *
     * @param to destionation address on sidechain.
     */
    function sendEthToSidechain(bytes32 to)
        external
        payable
        shouldBeInitialized
        shouldNotBePreparedForMigration
    {
        require(msg.value > 0, "ETH VALUE SHOULD BE MORE THAN 0");
        bytes32 empty;
        emit Deposit(to, msg.value, address(0x0), empty);
    }

    /**
     * Send ERC-20 token to sidechain.
     *
     * @param to destination address on the sidechain
     * @param amount amount to sendERC20ToSidechain
     * @param tokenAddress contract address of token to send
     */
    function sendERC20ToSidechain(
        bytes32 to,
        uint256 amount,
        address tokenAddress
    ) external shouldBeInitialized shouldNotBePreparedForMigration {
        IERC20 token = IERC20(tokenAddress);

        bytes32 sidechainAssetId = _sidechainTokensByAddress[tokenAddress];
        if (
            sidechainAssetId != "" ||
            _addressVAL == tokenAddress ||
            _addressXOR == tokenAddress
        ) {
            ERC20Burnable mtoken = ERC20Burnable(tokenAddress);
            mtoken.burnFrom(msg.sender, amount);
        } else {
            require(
                acceptedEthTokens[tokenAddress],
                "The Token is not accepted for transfer to sidechain"
            );
            uint256 balanceBefore = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = token.balanceOf(address(this));
            require(
                balanceAfter - balanceBefore >= amount,
                "Not enough tokens transferred"
            );
        }
        emit Deposit(to, amount, tokenAddress, sidechainAssetId);
    }

    /**
     * Add new peer using peers quorum.
     *
     * @param newPeerAddress address of the peer to add
     * @param txHash tx hash from sidechain
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function addPeerByPeer(
        address newPeerAddress,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized returns (bool) {
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        "addPeer",
                        newPeerAddress,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;

        addPeer(newPeerAddress);
        emit ChangePeers(newPeerAddress, false);
        return true;
    }

    /**
     * Remove peer using peers quorum.
     *
     * @param peerAddress address of the peer to remove
     * @param txHash tx hash from sidechain
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function removePeerByPeer(
        address peerAddress,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized returns (bool) {
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        "removePeer",
                        peerAddress,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;

        removePeer(peerAddress);
        emit ChangePeers(peerAddress, true);
        return true;
    }

    /**
     * Withdraws specified amount of ether or one of ERC-20 tokens to provided sidechain address
     * @param tokenAddress address of token to withdraw (0 for ether)
     * @param amount amount of tokens or ether to withdraw
     * @param to target account address
     * @param txHash hash of transaction from sidechain
     * @param from source of transfer
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function receiveByEthereumAssetAddress(
        address tokenAddress,
        uint256 amount,
        address payable to,
        address from,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized {
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        tokenAddress,
                        amount,
                        to,
                        from,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;

        if (tokenAddress == address(0)) {
            // untrusted transfer, relies on provided cryptographic proof
            to.transfer(amount);
        } else {
            IERC20 coin = IERC20(tokenAddress);
            // untrusted call, relies on provided cryptographic proof
            coin.safeTransfer(to, amount);
        }
        emit Withdrawal(txHash);
    }

    /**
     * Mint new Token
     * @param sidechainAssetId id of sidechainToken to mint
     * @param amount how much to mint
     * @param to destination address
     * @param from sender address
     * @param txHash hash of transaction from Iroha
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function receiveBySidechainAssetId(
        bytes32 sidechainAssetId,
        uint256 amount,
        address to,
        address from,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized {
        require(
            _sidechainTokens[sidechainAssetId] != address(0x0),
            "Sidechain asset is not registered"
        );
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        sidechainAssetId,
                        amount,
                        to,
                        from,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;

        MasterToken tokenInstance = MasterToken(
            _sidechainTokens[sidechainAssetId]
        );
        tokenInstance.mintTokens(to, amount);
        emit Withdrawal(txHash);
    }

    /**
     * Checks given addresses for duplicates and if they are peers signatures
     * @param hash unsigned data
     * @param v v-component of signature from hash
     * @param r r-component of signature from hash
     * @param s s-component of signature from hash
     * @return true if all given addresses are correct or false otherwise
     */
    function checkSignatures(
        bytes32 hash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) private returns (bool) {
        require(peersCount >= 1, "peersCount too low");
        uint256 signatureCount = v.length;
        require(
            signatureCount == r.length,
            "signatureCount and r length mismatch"
        );
        require(
            signatureCount == s.length,
            "signatureCount and s length mismatch"
        );
        uint256 needSigs = peersCount - (peersCount - 1) / 3;
        require(signatureCount >= needSigs, "not enough signatures");

        uint256 count;
        address[] memory recoveredAddresses = new address[](signatureCount);
        for (uint256 i; i < signatureCount; ++i) {
            address recoveredAddress = recoverAddress(hash, v[i], r[i], s[i]);

            // not a peer address or not unique
            if (
                isPeer[recoveredAddress] != true ||
                _uniqueAddresses[recoveredAddress] == true
            ) {
                continue;
            }
            recoveredAddresses[count] = recoveredAddress;
            unchecked {
                count = count + 1;
            }
            _uniqueAddresses[recoveredAddress] = true;
        }

        // restore state for future usages
        for (uint256 i; i < count; ++i) {
            _uniqueAddresses[recoveredAddresses[i]] = false;
        }

        return count >= needSigs;
    }

    /**
     * Recovers address from a given single signature
     * @param hash unsigned data
     * @param v v-component of signature from hash
     * @param r r-component of signature from hash
     * @param s s-component of signature from hash
     * @return address recovered from signature
     */
    function recoverAddress(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private pure returns (address) {
        bytes32 simple_hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address res = ecrecover(simple_hash, v, r, s);
        return res;
    }

    /**
     * Adds new peer to list of signature verifiers.
     * Internal function
     * @param newAddress address of new peer
     */
    function addPeer(address newAddress) internal returns (uint256) {
        require(isPeer[newAddress] == false, "peer already added");
        isPeer[newAddress] = true;
        ++peersCount;
        return peersCount;
    }

    function removePeer(address peerAddress) internal {
        require(isPeer[peerAddress] == true, "peer does not exists");
        isPeer[peerAddress] = false;
        --peersCount;
    }
}

// SPDX-License-Identifier: Apache License 2.0

pragma solidity =0.8.17;

import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MasterToken is ERC20Burnable, ERC20Detailed, Ownable {
    bytes32 public _sidechainAssetId;

    /**
     * @dev Constructor that gives the specified address all of existing tokens.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address beneficiary,
        uint256 supply,
        bytes32 sidechainAssetId
    ) ERC20Detailed(name, symbol, decimals) {
        _sidechainAssetId = sidechainAssetId;
        _mint(beneficiary, supply);
    }

    fallback() external {
        revert();
    }

    function mintTokens(address beneficiary, uint256 amount) public onlyOwner {
        _mint(beneficiary, amount);
    }
}

// SPDX-License-Identifier: Apache License 2.0

pragma solidity =0.8.17;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: Apache 2.0

pragma solidity =0.8.17;

import "./ERC20.sol";

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {
    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to send tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity =0.8.17;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: Apache License 2.0

pragma solidity =0.8.17;

interface EthTokenReciever {
    function receivePayment() external payable;
}

// SPDX-License-Identifier: Apache 2.0

pragma solidity =0.8.17;

import "./IERC20.sol";

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: Apache 2.0

pragma solidity =0.8.17;

import "./IERC20.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender] - value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0));

        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply + value;
        _balances[account] = _balances[account] + value;
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply - value;
        _balances[account] = _balances[account] - value;
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender] - value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity =0.8.17;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}