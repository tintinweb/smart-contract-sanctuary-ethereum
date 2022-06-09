// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Buyout} from "../../modules/Buyout.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {ERC1155} from "@rari-capital/solmate/src/tokens/ERC1155.sol";
import {IModule, IProtoform} from "../../interfaces/IProtoform.sol";
import {MerkleBase} from "../../utils/MerkleBase.sol";
import {Multicall} from "../../utils/Multicall.sol";
import {NFTReceiver} from "../../plugins/NFTReceiver.sol";
import {Supply} from "../../targets/Supply.sol";
import {Vault, VaultRegistry} from "../../VaultRegistry.sol";

/// @title BaseVault
/// @author Fraction Art
/// @notice Protoform contract for vault deployments with a fixed supply and buyout mechanism
contract BaseVault is IProtoform, MerkleBase, Multicall {
    /// @notice Buyout module contract
    Buyout public buyout;
    /// @notice NFTReciever plugin contract
    NFTReceiver public nftReceiver;
    /// @notice Supply target contract
    Supply public supply;
    /// @notice VaultRegistry contract
    VaultRegistry public registry;

    /// @notice Event log for modules that are enabled on a vault
    /// @param _vault The vault deployed
    /// @param _modules The modules being activated on deployed vault
    event ActiveModules(address indexed _vault, IModule[] _modules);

    /// @notice Initializes BaseVault Protoform with supply, buyout, and registry contracts
    /// @param _buyout The buyout module contract
    /// @param _nftReceiver Plugin contract for NFTReceiver hooks
    /// @param _supply The supply target contract
    /// @param _registry VaultRegistry contract
    constructor(
        Buyout _buyout,
        NFTReceiver _nftReceiver,
        Supply _supply,
        VaultRegistry _registry
    ) {
        buyout = _buyout;
        nftReceiver = _nftReceiver;
        supply = _supply;
        registry = _registry;
    }

    /// @notice Deploys a new Vault
    /// @param _fractionSupply Number of NFT Fractions minted to control the vault
    /// @param _modules The list of modules to be installed on the vault
    /// @param _mintProof List of proofs to execute a mint function
    function deployVault(
        uint256 _fractionSupply,
        IModule[] calldata _modules,
        bytes32[] calldata _mintProof
    ) external returns (Vault vault) {
        bytes32[] memory leafNodes = generateMerkleTree(_modules);
        bytes32 merkleRoot = getRoot(leafNodes);
        address[] memory plugins = new address[](3);
        bytes4[] memory selectors = new bytes4[](3);

        (selectors, plugins) = receiverPlugins();
        vault = registry.create(merkleRoot, plugins, selectors);
        emit ActiveModules(address(vault), _modules);

        initializeVault(vault, _fractionSupply, _mintProof);
    }

    /// @notice Transfers ERC1155 tokens
    /// @param _nfts[] NFT contracts
    /// @param _ids[] Ids of the token types
    /// @param _amounts[] Transfer amount
    /// @param _datas[] Additional transaction data
    /// @param _from Source address
    /// @param _to Target address
    function batchDepositERC1155(
        ERC1155[] calldata _nfts,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes[] calldata _datas,
        address _from,
        address _to
    ) external {
        for (uint256 i = 0; i < _nfts.length; i++)
            _nfts[i].safeTransferFrom(
                _from,
                _to,
                _ids[i],
                _amounts[i],
                _datas[i]
            );
    }

    /// @notice Transfers ERC20 tokens
    /// @param _tokens[] Token contract
    /// @param _amounts[] Transfer amount
    /// @param _from Source address
    /// @param _to Target address
    function batchDepositERC20(
        ERC20[] calldata _tokens,
        uint256[] calldata _amounts,
        address _from,
        address _to
    ) external {
        for (uint256 i = 0; i < _tokens.length; i++)
            _tokens[i].transferFrom(_from, _to, _amounts[i]);
    }

    /// @notice Transfers ERC721 tokens
    /// @param _nfts[] NFT contract
    /// @param _ids[] ID of the token
    /// @param _from Source address
    /// @param _to Target address
    function batchDepositERC721(
        ERC721[] calldata _nfts,
        uint256[] calldata _ids,
        address _from,
        address _to
    ) external {
        for (uint256 i = 0; i < _nfts.length; i++)
            _nfts[i].safeTransferFrom(_from, _to, _ids[i]);
    }

    /// @notice View function to return structs of permissions installed on vaults deployed with this Protoform
    /// @return permissions A list of Permission Structs
    function getPermissions()
        public
        view
        returns (VaultRegistry.Permission[] memory permissions)
    {
        permissions = new VaultRegistry.Permission[](6);
        permissions[0] = VaultRegistry.Permission(
            address(this),
            address(supply),
            supply.mint.selector
        );
        VaultRegistry.Permission[] memory buyoutPermissions = buyout
            .getPermissions();
        for (uint256 i; i < buyoutPermissions.length; ) {
            permissions[i + 1] = buyoutPermissions[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @notice View function to return the keccack256 hash of permissions installed on vaults deployed with this Protoform
    /// @return nodes A list of leaf nodes
    function getLeafNodes() public view returns (bytes32[] memory nodes) {
        nodes = new bytes32[](1);
        nodes[0] = keccak256(abi.encode(getPermissions()[0]));
    }

    /// @notice Generates a merkle tree from the hashed permission lists of the given modules
    /// @return hashes A combined list of leaf nodes
    function generateMerkleTree(IModule[] calldata _modules)
        public
        view
        returns (bytes32[] memory hashes)
    {
        hashes = new bytes32[](6);
        unchecked {
            for (uint256 i; i < _modules.length; ++i) {
                bytes32[] memory leaves = _modules[i].getLeafNodes();
                for (uint256 j; j < leaves.length; ++j) {
                    hashes[i + j] = leaves[j];
                }
            }
        }
    }

    /// @notice Returns the plugin implementation and selectors for receiving NFTs
    /// @return selectors The function selectors to enable on the vault
    /// @return plugins Plugin implementation addresses
    function receiverPlugins()
        public
        view
        returns (bytes4[] memory selectors, address[] memory plugins)
    {
        plugins = new address[](3);
        selectors = new bytes4[](3);

        (plugins[0], plugins[1], plugins[2]) = (
            address(nftReceiver),
            address(nftReceiver),
            address(nftReceiver)
        );
        (selectors[0], selectors[1], selectors[2]) = (
            nftReceiver.onERC1155Received.selector,
            nftReceiver.onERC1155BatchReceived.selector,
            nftReceiver.onERC721Received.selector
        );
    }

    /// @notice Initializes a new Vault and mints fractions
    /// @param _vault The Vault performing the mint
    /// @param _fractionSupply Number of NFT Fractions minted to control the vault
    /// @param _mintProof List of proofs to execute a mint function
    function initializeVault(
        Vault _vault,
        uint256 _fractionSupply,
        bytes32[] calldata _mintProof
    ) internal {
        bytes memory data = abi.encodeCall(
            supply.mint,
            (msg.sender, _fractionSupply)
        );
        _vault.execute(address(supply), data, _mintProof);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {BuyoutError} from "../reverts/BuyoutError.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {ERC1155, ERC1155TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC1155.sol";
import {FERC1155, Vault, VaultRegistry} from "../VaultRegistry.sol";
import {IModule} from "../interfaces/IModule.sol";
import {Multicall} from "../utils/Multicall.sol";
import {SafeSend} from "../utils/SafeSend.sol";
import {SelfPermit} from "../utils/SelfPermit.sol";
import {Supply} from "../targets/Supply.sol";
import {Transfer} from "../targets/Transfer.sol";

/// @title Buyout
/// @author Fractional Art
/// @notice Module contract for vaults to hold buyout pools
/// - A fractional owner starts an auction for a vault by depositing any amount of ether and fractional tokens into a pool.
/// - During the proposal period (2 days) users can sell their fractional tokens into the pool for ether.
/// - During the rejection period (4 days) users can buy fractional tokens from the pool with ether.
/// - If a pool has more than 51% of the total supply after 4 days, the buyout is successful and the proposer
///   gains access to withdraw the underlying assets (ERC20, ERC721, and ERC1155 tokens) from the vault.
///   Otherwise the buyout is considered unsuccessful and a new one may then begin.
/// - NOTE: A vault may only have one active buyout at any given time.
/// - buyoutPrice = (ethDeposit * 100) / (100 - ((fractionDeposit * 100) / totalSupply))
/// - buyoutShare = (tokenBalance * ethBalance) / (totalSupply + tokenBalance)
contract Buyout is
    ERC1155TokenReceiver,
    IModule,
    Multicall,
    SafeSend,
    SelfPermit
{
    /// @notice VaultRegistry contract
    VaultRegistry public registry;
    /// @notice Supply target contract
    Supply public supply;
    /// @notice Transfer target contract
    Transfer public transfer;
    /// @notice Time length of the proposal period
    uint256 public constant PROPOSAL_PERIOD = 2 days;
    /// @notice Time length of the rejection period
    uint256 public constant REJECTION_PERIOD = 4 days;
    /// @notice Mapping of vault address to auction struct
    mapping(address => Auction) public buyoutInfo;
    /// @notice Possible states that an auction may have
    enum State {
        INACTIVE,
        LIVE,
        SUCCESS
    }

    /// @notice Auction information
    struct Auction {
        // Time of when buyout begins
        uint256 startTime;
        // Address of proposer creating buyout
        address proposer;
        // Enum state of the buyout auction
        State state;
        // Price of fractional tokens
        uint256 fractionPrice;
        // Balance of ether in buyout pool
        uint256 ethBalance;
        // Total supply recorded before a buyout started
        uint256 lastTotalSupply;
    }

    /// @notice Event log for starting a buyout
    /// @param _vault Address of the vault
    /// @param _proposer Address that created the buyout
    /// @param _startTime Timestamp of when buyout was created
    /// @param _buyoutPrice Price of buyout pool in ether
    /// @param _fractionPrice Price of fractional tokens
    event Start(
        address indexed _vault,
        address indexed _proposer,
        uint256 _startTime,
        uint256 _buyoutPrice,
        uint256 _fractionPrice
    );
    /// @notice Event log for selling fractional tokens into the buyout pool
    /// @param _seller Address selling fractions
    /// @param _amount Transfer amount being sold
    event SellFractions(address indexed _seller, uint256 _amount);
    /// @notice Event log for buying fractional tokens from the buyout pool
    /// @param _buyer Address buying fractions
    /// @param _amount Transfer amount being bought
    event BuyFractions(address indexed _buyer, uint256 _amount);
    /// @notice Event log for ending an active buyout
    /// @param _state Enum state of auction
    /// @param _vault Address of the vault
    /// @param _proposer Address that created the buyout
    event End(address indexed _vault, State _state, address indexed _proposer);
    /// @notice Event log for cashing out ether for fractions from a successful buyout
    /// @param _vault Address of the vault
    /// @param _casher Address cashing out of buyout
    /// @param _amount Transfer amount of ether
    event Cash(
        address indexed _vault,
        address indexed _casher,
        uint256 _amount
    );
    /// @notice Event log for redeeming the underlying vault assets from an inactive buyout
    /// @param _vault Address of the vault
    /// @param _redeemer Address redeeming underlying assets
    event Redeem(address indexed _vault, address indexed _redeemer);

    /// @notice Initializes supply, transfer, and registry contracts
    constructor(
        VaultRegistry _registry,
        Supply _supply,
        Transfer _transfer
    ) {
        registry = _registry;
        supply = _supply;
        transfer = _transfer;
    }

    /// @dev Callback for receiving ether when the calldata is empty
    receive() external payable {}

    /// @notice Starts the auction for a buyout pool
    /// @param _vault Address of the vault
    function start(address _vault) external payable {
        // Reverts if ether deposit amount is zero
        if (msg.value == 0) revert BuyoutError.ZeroDeposit();
        // Reverts if address is not a registered vault
        (FERC1155 token, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        // Reverts if auction state is not inactive
        (, , State current, , , ) = this.buyoutInfo(_vault);
        State required = State.INACTIVE;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);

        // Gets total supply of fractional tokens for the vault
        uint256 totalSupply = registry.totalSupply(_vault);
        // Gets total balance of fractional tokens owned by caller
        uint256 depositAmount = token.balanceOf(msg.sender, id);

        // Transfers fractional tokens into the buyout pool
        token.safeTransferFrom(
            msg.sender,
            address(this),
            id,
            depositAmount,
            ""
        );

        // Calculates price of buyout and fractions
        // @dev Reverts with division error if called with total supply of tokens
        uint256 buyoutPrice = (msg.value * 100) /
            (100 - ((depositAmount * 100) / totalSupply));
        uint256 fractionPrice = buyoutPrice / totalSupply;

        // Sets info mapping of the vault address to auction struct
        buyoutInfo[_vault] = Auction(
            block.timestamp,
            msg.sender,
            State.LIVE,
            fractionPrice,
            msg.value,
            totalSupply
        );
        // Emits event for starting auction
        emit Start(
            _vault,
            msg.sender,
            block.timestamp,
            buyoutPrice,
            fractionPrice
        );
    }

    /// @notice Sells fractional tokens in exchange for ether from a pool
    /// @param _vault Address of the vault
    /// @param _amount Transfer amount of fractions
    function sellFractions(address _vault, uint256 _amount) external {
        // Reverts if address is not a registered vault
        (FERC1155 token, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        (uint256 startTime, , State current, uint256 fractionPrice, , ) = this
            .buyoutInfo(_vault);
        // Reverts if auction state is not live
        State required = State.LIVE;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);
        // Reverts if current time is greater than end time of proposal period
        uint256 endTime = startTime + PROPOSAL_PERIOD;
        if (block.timestamp > endTime)
            revert BuyoutError.TimeExpired(block.timestamp, endTime);

        // Transfers fractional tokens to pool from caller
        token.safeTransferFrom(msg.sender, address(this), id, _amount, "");

        // Updates ether balance of pool
        uint256 ethAmount = fractionPrice * _amount;
        buyoutInfo[_vault].ethBalance -= ethAmount;
        // Transfers ether amount to caller
        _sendEthOrWeth(msg.sender, ethAmount);
        // Emits event for selling fractions into pool
        emit SellFractions(msg.sender, _amount);
    }

    /// @notice Buys fractional tokens in exchange for ether from a pool
    /// @param _vault Address of the vault
    /// @param _amount Transfer amount of fractions
    function buyFractions(address _vault, uint256 _amount) external payable {
        // Reverts if address is not a registered vault
        (FERC1155 token, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        // Reverts if auction state is not live
        (uint256 startTime, , State current, uint256 fractionPrice, , ) = this
            .buyoutInfo(_vault);
        State required = State.LIVE;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);
        // Reverts if current time is greater than end time of rejection period
        uint256 endTime = startTime + REJECTION_PERIOD;
        if (block.timestamp > endTime)
            revert BuyoutError.TimeExpired(block.timestamp, endTime);
        // Reverts if payment amount does not equal price of fractional amount
        if (msg.value != fractionPrice * _amount)
            revert BuyoutError.InvalidPayment();

        // Transfers fractional tokens to caller
        token.safeTransferFrom(address(this), msg.sender, id, _amount, "");
        // Updates ether balance of pool
        buyoutInfo[_vault].ethBalance += msg.value;
        // Emits event for buying fractions from pool
        emit BuyFractions(msg.sender, _amount);
    }

    /// @notice Ends the auction for a live buyout pool
    /// @param _vault Address of the vault
    /// @param _burnProof Merkle proof for burning fractional tokens
    function end(address _vault, bytes32[] calldata _burnProof) external {
        // Reverts if address is not a registered vault
        (FERC1155 token, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        // Reverts if auction state is not live
        (
            uint256 startTime,
            address proposer,
            State current,
            ,
            uint256 ethBalance,

        ) = this.buyoutInfo(_vault);
        State required = State.LIVE;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);
        // Reverts if current time is less than or equal to end time of auction
        uint256 endTime = startTime + REJECTION_PERIOD;
        if (block.timestamp <= endTime)
            revert BuyoutError.TimeNotElapsed(block.timestamp, endTime);

        uint256 tokenBalance = token.balanceOf(address(this), id);
        // Checks totalSupply of auction pool to determine if buyout is successful or not
        if ((tokenBalance * 1000) / registry.totalSupply(_vault) > 500) {
            // Initializes vault transaction
            bytes memory data = abi.encodeCall(
                supply.burn,
                (address(this), tokenBalance)
            );
            // Executes burn of fractional tokens from pool
            Vault(payable(_vault)).execute(address(supply), data, _burnProof);
            // Sets buyout state to successful
            buyoutInfo[_vault].state = State.SUCCESS;
            // Emits event for ending successful auction
            emit End(_vault, State.SUCCESS, proposer);
        } else {
            // Deletes auction info
            delete buyoutInfo[_vault];
            // Transfers fractions and ether back to proposer of the buyout pool
            token.safeTransferFrom(
                address(this),
                proposer,
                id,
                tokenBalance,
                ""
            );
            _sendEthOrWeth(proposer, ethBalance);
            // Emits event for ending unsuccessful auction
            emit End(_vault, State.INACTIVE, proposer);
        }
    }

    /// @notice Cashes out proceeds from a successful buyout
    /// @param _vault Address of the vault
    /// @param _burnProof Merkle proof for burning fractional tokens
    function cash(address _vault, bytes32[] calldata _burnProof) external {
        // Reverts if address is not a registered vault
        (FERC1155 token, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        // Reverts if auction state is not successful
        (, , State current, , uint256 ethBalance, ) = this.buyoutInfo(_vault);
        State required = State.SUCCESS;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);
        // Reverts if caller has a balance of zero fractional tokens
        uint256 tokenBalance = token.balanceOf(msg.sender, id);
        if (tokenBalance == 0) revert BuyoutError.NoFractions();

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            supply.burn,
            (msg.sender, tokenBalance)
        );
        // Executes burn of fractional tokens from caller
        Vault(payable(_vault)).execute(address(supply), data, _burnProof);

        // Transfers buyout share amount to caller based on total supply
        uint256 totalSupply = registry.totalSupply(_vault);
        uint256 buyoutShare = (tokenBalance * ethBalance) /
            (totalSupply + tokenBalance);
        _sendEthOrWeth(msg.sender, buyoutShare);
        // Emits event for cashing out of buyout pool
        emit Cash(_vault, msg.sender, buyoutShare);
    }

    /// @notice Terminates a vault with an inactive buyout
    /// @param _vault Address of the vault
    /// @param _burnProof Merkle proof for burning fractional tokens
    function redeem(address _vault, bytes32[] calldata _burnProof) external {
        // Reverts if address is not a registered vault
        (, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        // Reverts if auction state is not inactive
        (, , State current, , , ) = this.buyoutInfo(_vault);
        State required = State.INACTIVE;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);

        // Initializes vault transaction
        uint256 totalSupply = registry.totalSupply(_vault);
        bytes memory data = abi.encodeCall(
            supply.burn,
            (msg.sender, totalSupply)
        );
        // Executes burn of fractional tokens from caller
        Vault(payable(_vault)).execute(address(supply), data, _burnProof);

        // Sets buyout state to successful and proposer to caller
        (buyoutInfo[_vault].state, buyoutInfo[_vault].proposer) = (
            State.SUCCESS,
            msg.sender
        );
        // Emits event for redeem underlying assets from the vault
        emit Redeem(_vault, msg.sender);
    }

    /// @notice Withdraws an ERC-20 token from a vault
    /// @param _vault Address of the vault
    /// @param _token ERC-20 token contract
    /// @param _value Transfer amount
    /// @param _erc20TransferProof Merkle proof for transferring an ERC-20 token
    function withdrawERC20(
        address _vault,
        ERC20 _token,
        uint256 _value,
        bytes32[] calldata _erc20TransferProof
    ) external {
        // Reverts if address is not a registered vault
        (, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        // Reverts if auction state is not successful
        (, address proposer, State current, , , ) = this.buyoutInfo(_vault);
        State required = State.SUCCESS;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);
        // Reverts if caller is not the auction winner
        if (msg.sender != proposer) revert BuyoutError.NotWinner();

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            transfer.ERC20Transfer,
            (_token, msg.sender, _value)
        );
        // Executes transfer of ERC721 token to caller
        Vault(payable(_vault)).execute(
            address(transfer),
            data,
            _erc20TransferProof
        );
    }

    /// @notice Withdraws an ERC-721 token from a vault
    /// @param _vault Address of the vault
    /// @param _nft ERC-721 token contract
    /// @param _tokenId ID of the token
    /// @param _erc721TransferProof Merkle proof for transferring an ERC-721 token
    function withdrawERC721(
        address _vault,
        ERC721 _nft,
        uint256 _tokenId,
        bytes32[] calldata _erc721TransferProof
    ) external {
        // Reverts if address is not a registered vault
        (, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        // Reverts if auction state is not successful
        (, address proposer, State current, , , ) = this.buyoutInfo(_vault);
        State required = State.SUCCESS;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);
        // Reverts if caller is not the auction winner
        if (msg.sender != proposer) revert BuyoutError.NotWinner();

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            transfer.ERC721TransferFrom,
            (_nft, _vault, proposer, _tokenId)
        );
        // Executes transfer of ERC721 token to caller
        Vault(payable(_vault)).execute(
            address(transfer),
            data,
            _erc721TransferProof
        );
    }

    /// @notice Withdraws an ERC1155 token from a vault
    /// @param _vault Address of the vault
    /// @param _nft ERC-1155 token contract
    /// @param _id ID of the token type
    /// @param _value Transfer amount
    /// @param _data Additional transaction data
    /// @param _erc1155TransferProof Merkle proof for transferring an ERC-1155 token
    function withdrawERC1155(
        address _vault,
        ERC1155 _nft,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        bytes32[] calldata _erc1155TransferProof
    ) external {
        // Reverts if address is not a registered vault
        (, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        // Reverts if auction state is not successful
        (, address proposer, State current, , , ) = this.buyoutInfo(_vault);
        State required = State.SUCCESS;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);
        // Reverts if caller is not the auction winner
        if (msg.sender != proposer) revert BuyoutError.NotWinner();

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            transfer.ERC1155TransferFrom,
            (_nft, _vault, proposer, _id, _value, _data)
        );
        // Executes transfer of ERC1155 token to caller
        Vault(payable(_vault)).execute(
            address(transfer),
            data,
            _erc1155TransferProof
        );
    }

    /// @notice Batch withdraws ERC-1155 tokens from a vault
    /// @param _vault Address of the vault
    /// @param _nft ERC-1155 token contract
    /// @param _ids IDs of each token type
    /// @param _values Transfer amounts per token type
    /// @param _erc1155BatchTransferProof Merkle proof for transferring multiple ERC-1155 tokens
    function batchWithdrawERC1155(
        address _vault,
        ERC1155 _nft,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes32[] calldata _erc1155BatchTransferProof
    ) external {
        // Reverts if address is not a registered vault
        (, uint256 id) = registry.vaultToToken(_vault);
        if (id == 0) revert BuyoutError.NotVault(_vault);
        // Reverts if auction state is not successful
        (, address proposer, State current, , , ) = this.buyoutInfo(_vault);
        State required = State.SUCCESS;
        if (current != required)
            revert BuyoutError.InvalidState(required, current);
        // Reverts if caller is not the auction winner
        if (msg.sender != proposer) revert BuyoutError.NotWinner();

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            transfer.ERC1155BatchTransferFrom,
            (_nft, _vault, proposer, _ids, _values, "")
        );
        // Executes batch transfer of multiple ERC1155 tokens to caller
        Vault(payable(_vault)).execute(
            address(transfer),
            data,
            _erc1155BatchTransferProof
        );
    }

    /// @notice Handles the receipt of a single ERC1155 token type
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @notice Handles the receipt of multiple ERC1155 token types
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    /// @notice Gets the list of leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return nodes Hashes of leaf nodes
    function getLeafNodes() external view returns (bytes32[] memory nodes) {
        nodes = new bytes32[](5);
        // Gets list of permissions from this module
        VaultRegistry.Permission[] memory permissions = getPermissions();
        for (uint256 i; i < permissions.length; ) {
            // Hashes permission into leaf node
            nodes[i] = keccak256(abi.encode(permissions[i]));
            // Can't overflow since loop is a fixed size
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Gets the list of permissions used on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions List of vault permissions
    function getPermissions()
        public
        view
        returns (VaultRegistry.Permission[] memory permissions)
    {
        permissions = new VaultRegistry.Permission[](5);
        // Burn function selector from supply contract
        permissions[0] = VaultRegistry.Permission(
            address(this),
            address(supply),
            supply.burn.selector
        );
        // ERC20Transfer function selector from transfer contract
        permissions[1] = VaultRegistry.Permission(
            address(this),
            address(transfer),
            transfer.ERC20Transfer.selector
        );
        // ERC721TransferFrom function selector from transfer contract
        permissions[2] = VaultRegistry.Permission(
            address(this),
            address(transfer),
            transfer.ERC721TransferFrom.selector
        );
        // ERC1155TransferFrom function selector from transfer contract
        permissions[3] = VaultRegistry.Permission(
            address(this),
            address(transfer),
            transfer.ERC1155TransferFrom.selector
        );
        // ERC1155BatchTransferFrom function selector from transfer contract
        permissions[4] = VaultRegistry.Permission(
            address(this),
            address(transfer),
            transfer.ERC1155BatchTransferFrom.selector
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import {IModule} from "./IModule.sol";
import {VaultRegistry, Vault} from "../VaultRegistry.sol";

interface IProtoform is IModule {
    function generateMerkleTree(IModule[] calldata modules)
        external
        view
        returns (bytes32[] memory hashes);

    function deployVault(
        uint256 fAmount,
        IModule[] calldata modules,
        bytes32[] calldata proof
    ) external returns (Vault vault);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Merkle Base
/// @author Modified from dmfxyz (https://github.com/dmfxyz/murky/blob/main/src/common/MurkyBase.sol)
/// @notice Utility contract for generating merkle roots and verifying proofs
abstract contract MerkleBase {
    /***************
     * CONSTRUCTOR *
     ***************/
    constructor() {}

    /********************
     * HASING FUNCTIONS *
     ********************/

    /// @notice Hashes two leaf pairs
    /// @param _left Node on left side of tree level
    /// @param _right Node on right side of tree level
    /// @return data Result hash of node params
    function hashLeafPairs(bytes32 _left, bytes32 _right)
        public
        pure
        returns (bytes32 data)
    {
        // Return opposite node if checked node is of bytes zero value
        if (_left == bytes32(0)) return _right;
        if (_right == bytes32(0)) return _left;

        assembly {
            // TODO: This can be aesthetically simplified with a switch. Not sure it will
            // save much gas but there are other optimizations to be had in here.
            if or(lt(_left, _right), eq(_left, _right)) {
                mstore(0x0, _left)
                mstore(0x20, _right)
            }
            if gt(_left, _right) {
                mstore(0x0, _right)
                mstore(0x20, _left)
            }
            data := keccak256(0x0, 0x40)
        }
    }

    /**********************
     * PROOF VERIFICATION *
     **********************/

    /// @notice Verifies the merkle proof of a given value
    /// @param _root Hash of merkle root
    /// @param _proof Merkle proof
    /// @param _valueToProve Leaf node being proven
    /// @return Status of proof verification
    function verifyProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _valueToProve
    ) public pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = _valueToProve;
        unchecked {
            for (uint256 i = 0; i < _proof.length; ++i) {
                rollingHash = hashLeafPairs(rollingHash, _proof[i]);
            }
        }
        return _root == rollingHash;
    }

    /********************
     * PROOF GENERATION *
     ********************/

    /// @notice Generates the merkle root of a tree
    /// @param _data Leaf nodes of the merkle tree
    /// @return Hash of merkle root
    function getRoot(bytes32[] memory _data) public pure returns (bytes32) {
        require(_data.length > 1, "wont generate root for single leaf");
        while (_data.length > 1) {
            _data = hashLevel(_data);
        }
        return _data[0];
    }

    /// @notice Generates the merkle proof for a leaf node in a given tree
    /// @param _data Leaf nodes of the merkle tree
    /// @param _node Index of the node in the tree
    /// @return Merkle proof
    function getProof(bytes32[] memory _data, uint256 _node)
        public
        pure
        returns (bytes32[] memory)
    {
        require(_data.length > 1, "wont generate proof for single leaf");
        // The size of the proof is equal to the ceiling of log2(numLeaves)
        uint256 size = log2ceil_naive(_data.length);
        bytes32[] memory result = new bytes32[](size);
        uint256 pos;
        uint256 counter;

        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        while (_data.length > 1) {
            unchecked {
                if (_node % 2 == 1) {
                    result[pos] = _data[_node - 1];
                } else if (_node + 1 == _data.length) {
                    result[pos] = bytes32(0);
                    ++counter;
                } else {
                    result[pos] = _data[_node + 1];
                }
                ++pos;
                _node = _node / 2;
            }
            _data = hashLevel(_data);
        }

        bytes32[] memory arr = new bytes32[](size - counter);
        unchecked {
            uint256 offset;
            for (uint256 i; i < result.length; ++i) {
                if (result[i] != bytes32(0)) {
                    arr[i - offset] = result[i];
                } else {
                    ++offset;
                }
            }
        }

        return arr;
    }

    /// @notice Hashes nodes at the given tree level
    /// @param _data Nodes at the current level
    /// @return result Hashes of nodes at the next level
    function hashLevel(bytes32[] memory _data)
        internal
        pure
        returns (bytes32[] memory result)
    {
        // TODO: can store data.length to avoid mload calls
        if (_data.length % 2 == 1) {
            result = new bytes32[](_data.length / 2 + 1);
            result[result.length - 1] = hashLeafPairs(
                _data[_data.length - 1],
                bytes32(0)
            );
        } else {
            result = new bytes32[](_data.length / 2);
        }

        // pos is upper bounded by data.length / 2, so safe even if array is at max size
        unchecked {
            uint256 pos;
            for (uint256 i = 0; i < _data.length - 1; i += 2) {
                result[pos] = hashLeafPairs(_data[i], _data[i + 1]);
                ++pos;
            }
        }
    }

    /******************
     * MATH "LIBRARY" *
     ******************/

    /// @notice Calculates proof size based on size of tree
    /// @dev Note that x is assumed > 0 and proof size is not precise
    /// @param x Size of the merkle tree
    /// @return ceil Rounded value of proof size
    function log2ceil_naive(uint256 x) public pure returns (uint256 ceil) {
        uint256 lsb = (~x + 1) & x;
        bool powerOf2 = x == lsb;

        // if x == type(uint256).max, than ceil is capped at 256
        // if x == 0, then (~x + 1) & x == 0, so ceil won't underflow
        unchecked {
            while (x > 0) {
                x >>= 1;
                ceil++;
            }
            if (powerOf2) {
                ceil--;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

/// @title Multicall
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// @notice Utility contract that enables calling multiple local methods in a single call
abstract contract Multicall {
    /// @notice Allows multiple function calls within a contract that inherits from it
    /// @param _data List of encoded function calls to make in this contract
    /// @return results List of return responses for each encoded call passed
    function multicall(bytes[] calldata _data)
        external
        returns (bytes[] memory results)
    {
        uint256 length = _data.length;
        results = new bytes[](length);

        bool success;
        for (uint256 i; i < length; ) {
            bytes memory result;
            (success, result) = address(this).delegatecall(_data[i]);
            if (!success) {
                if (result.length == 0) revert();
                // If there is return data and the call wasn't successful, the call reverted with a reason or a custom error.
                _revertedWithReason(result);
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Handles function for revert responses
    /// @param _response Reverted return response from a delegate call
    function _revertedWithReason(bytes memory _response) internal pure {
        assembly {
            let returndata_size := mload(_response)
            revert(add(32, _response), returndata_size)
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import {ERC721TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {ERC1155TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC1155.sol";

/// @title NFT Receiver
/// @author Fractional Art
/// @notice Plugin contract for handling receipts of non-fungible tokens
contract NFTReceiver is ERC721TokenReceiver, ERC1155TokenReceiver {
    /// @notice Handles the receipt of a single ERC721 token
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    /// @notice Handles the receipt of a single ERC1155 token type
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @notice Handles the receipt of multiple ERC1155 token types
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {VaultRegistry} from "../VaultRegistry.sol";

/// @title Supply
/// @author Fractional Art
/// @notice Target contract for minting and burning fractional tokens
contract Supply {
    /// @notice VaultRegistry contract
    VaultRegistry immutable registry;

    /// @notice Initializes registry contract
    constructor(VaultRegistry _registry) {
        registry = _registry;
    }

    /// @notice Mints fractional tokens
    /// @param _to Target address
    /// @param _value Transfer amount
    function mint(address _to, uint256 _value) external {
        registry.mint(_to, _value, "");
    }

    /// @notice Burns fractional tokens
    /// @param _from Source address
    /// @param _value Burn amount
    function burn(address _from, uint256 _value) external {
        registry.burn(_from, _value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/src/ClonesWithImmutableArgs.sol";
import {FERC1155} from "./FERC1155.sol";
import {Metadata} from "./utils/Metadata.sol";
import {RegistryError} from "./reverts/RegistryError.sol";
import {Vault, VaultFactory} from "./VaultFactory.sol";

/// @title Vault Registry
/// @author Fractional Art
/// @notice Registry contract for tracking all fractional vaults
contract VaultRegistry {
    /// @dev Use clones library with address types
    using ClonesWithImmutableArgs for address;
    /// @notice Implementation for FERC1155 token contract
    address public immutable fNFTImplementation;
    /// @notice FERC1155 token contract
    FERC1155 public immutable fNFT;
    /// @notice VaultFactory contract
    VaultFactory public immutable factory;
    /// @notice Mapping of collection address to next token ID type
    mapping(address => uint256) public nextId;
    /// @notice Mapping of vault address to vault information
    mapping(address => VaultInfo) public vaultToToken;

    /// @notice Vault information
    struct VaultInfo {
        // FERC1155 token contract
        FERC1155 token;
        // ID of the token type
        uint256 id;
    }

    /// @notice Vault permissions
    struct Permission {
        // Address of module contract
        address module;
        // Address of target contract
        address target;
        // Function selector from target contract
        bytes4 selector;
    }

    /// @notice Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _id Id of the token
    event VaultDeployed(
        address indexed _vault,
        address indexed _token,
        uint256 _id
    );

    /// @notice Initializes factory and token contracts
    constructor() {
        factory = new VaultFactory();
        fNFTImplementation = address(new FERC1155());
        fNFT = FERC1155(
            fNFTImplementation.clone(
                abi.encodePacked(
                    block.chainid,
                    FERC1155(fNFTImplementation).DOMAIN_SEPARATOR(),
                    msg.sender,
                    address(this)
                )
            )
        );
    }

    /// @notice Gets the total supply for a token and ID associated with a vault
    /// @param _vault Address of the vault
    /// @return Total supply
    function totalSupply(address _vault) external view returns (uint256) {
        VaultInfo memory info = vaultToToken[_vault];
        return info.token.totalSupply(info.id);
    }

    /// @notice Gets the uri for a given token and ID associated with a vault
    /// @param _vault Address of the vault
    /// @return URI of token
    function uri(address _vault) external view returns (string memory) {
        VaultInfo memory info = vaultToToken[_vault];
        return info.token.uri(info.id);
    }

    /// @notice Creates a new vault with permissions and plugins
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Proxy contract
    function create(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) public returns (Vault vault) {
        vault = deployVault(_merkleRoot, fNFT, _plugins, _selectors);
    }

    /// @notice Creates a new vault with permissions and plugins, and transfers ownership to a given owner
    /// @dev This should only be done in limited cases i.e. if you're okay with a trusted individual(s)
    /// having control over the vault. Ideally, execution would be locked behind a multisig wallet.
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _owner Address of the vault owner
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Proxy contract
    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) public returns (Vault vault) {
        vault = deployVault(_merkleRoot, fNFT, _plugins, _selectors);
        vault.transferOwnership(_owner);
    }

    /// @notice Creates a new vault with permissions and plugins for the message sender
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Proxy contract
    /// @return token FERC1155 contract
    function createCollection(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) public returns (Vault vault, FERC1155 token) {
        (vault, token) = createCollectionFor(
            _merkleRoot,
            msg.sender,
            _plugins,
            _selectors
        );
    }

    /// @notice Creates a new vault with permissions and plugins for a given controller
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _controller Address of token controller
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Proxy contract
    /// @return token FERC1155 contract
    function createCollectionFor(
        bytes32 _merkleRoot,
        address _controller,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) public returns (Vault vault, FERC1155 token) {
        token = FERC1155(
            fNFTImplementation.clone(
                abi.encodePacked(
                    block.chainid,
                    FERC1155(fNFTImplementation).DOMAIN_SEPARATOR(),
                    _controller,
                    address(this)
                )
            )
        );
        vault = deployVault(_merkleRoot, token, _plugins, _selectors);
    }

    /// @notice Creates a new vault with permissions and plugins for an existing collection
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _token FERC1155 contract
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Proxy contract
    function createInCollection(
        bytes32 _merkleRoot,
        FERC1155 _token,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) public returns (Vault vault) {
        address controller = _token.controller();
        if (controller != msg.sender)
            revert RegistryError.NotController(controller, msg.sender);
        vault = deployVault(_merkleRoot, _token, _plugins, _selectors);
    }

    /// @notice Mints vault tokens
    /// @param _to Target address
    /// @param _value Amount of tokens
    /// @param _data Additional transaction data
    function mint(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public {
        VaultInfo memory info = vaultToToken[msg.sender];
        uint256 id = info.id;
        if (id == 0) revert RegistryError.NotVault(msg.sender);
        info.token.mint(_to, id, _value, _data);
    }

    /// @notice Burns vault tokens
    /// @param _from Source address
    /// @param _value Amount of tokens
    function burn(address _from, uint256 _value) public {
        VaultInfo memory info = vaultToToken[msg.sender];
        uint256 id = info.id;
        if (id == 0) revert RegistryError.NotVault(msg.sender);
        info.token.burn(_from, id, _value);
    }

    /// @notice Deploys new vault for specified token, sets merkle root, and installs plugins
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _token FERC1155 contract
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Proxy contract
    function deployVault(
        bytes32 _merkleRoot,
        FERC1155 _token,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) internal returns (Vault vault) {
        vault = Vault(factory.deploy());
        vaultToToken[address(vault)] = VaultInfo(
            _token,
            ++nextId[address(_token)]
        );
        vault.setMerkleRoot(_merkleRoot);
        vault.install(_selectors, _plugins);
        emit VaultDeployed(
            address(vault),
            address(_token),
            nextId[address(_token)]
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Buyout} from "../modules/Buyout.sol";

library BuyoutError {
    /// @notice Emitted when the payment amount does not equal the fractional price
    error InvalidPayment();

    /// @notice Emitted when the buyout state is invalid
    error InvalidState(Buyout.State _required, Buyout.State _current);

    /// @notice Emitted when the caller has no balance of fractional tokens
    error NoFractions();

    /// @notice Emitted when the caller is not the winner of an auction
    error NotWinner();

    /// @notice Emitted when the address is not a registered vault
    error NotVault(address _vault);

    /// @notice Emitted when the time has expired for selling and buying fractions
    error TimeExpired(uint256 _current, uint256 _deadline);

    /// @notice Emitted when the buyout auction is still active
    error TimeNotElapsed(uint256 _current, uint256 _deadline);

    /// @notice Emitted when ether deposit amount for starting a buyout is zero
    error ZeroDeposit();
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import {VaultRegistry} from "../VaultRegistry.sol";

interface IModule {
    function getPermissions()
        external
        view
        returns (VaultRegistry.Permission[] memory);

    function getLeafNodes() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {WETH} from "@rari-capital/solmate/src/tokens/WETH.sol";

/// @title SafeSend
/// @author Fractional Art
/// @notice Utility contract for sending Ether or WETH value to an address
abstract contract SafeSend {
    /// @notice Address for WETH contract on mainnet
    address payable public constant WETH_ADDRESS =
        payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice Attempts to send ether to an address
    /// @param _to Address attemping to send to
    /// @param _value Amount to send
    /// @return success Status of transfer
    function _attemptETHTransfer(address _to, uint256 _value)
        internal
        returns (bool success)
    {
        assembly {
            success := call(gas(), _to, _value, 0, 0, 0, 0)
        }
    }

    /// @notice Sends eth or weth to an address
    /// @param _to Address to send to
    /// @param _value Amount to send
    function _sendEthOrWeth(address _to, uint256 _value) internal {
        if (!_attemptETHTransfer(_to, _value)) {
            WETH(WETH_ADDRESS).deposit{value: _value}();
            WETH(WETH_ADDRESS).transfer(_to, _value);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import {FERC1155} from "../FERC1155.sol";

/// @title SelfPermit
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/SelfPermit.sol)
/// @notice Utility contract for executing a permit signature to update the approval status in an FERC1155 contract
abstract contract SelfPermit {
    /// @notice Caller executes permit using their own signature for an ID type of an ERC1155 token
    /// @param _token ERC1155 token with permit
    /// @param _operator Account being approved
    /// @param _id ID type being approved
    /// @param _approved Approval status for the token
    /// @param _deadline Deadline for when the signature expires
    /// @param _v The recovery ID (129th byte and chain ID) of the signature used to recover the signer
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function selfPermit(
        FERC1155 _token,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        _token.permit(
            msg.sender,
            _operator,
            _id,
            _approved,
            _deadline,
            _v,
            _r,
            _s
        );
    }

    /// @notice Caller executes permit using their own signature for all ID types of an ERC1155 token
    /// @param _token ERC1155 token with permit
    /// @param _operator Account being approved
    /// @param _approved Approval status for the token
    /// @param _deadline Deadline for when the signature expires
    /// @param _v The recovery ID (129th byte and chain ID) of the signature used to recover the signer
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function selfPermitAll(
        FERC1155 _token,
        address _operator,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        _token.permitAll(
            msg.sender,
            _operator,
            _approved,
            _deadline,
            _v,
            _r,
            _s
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {ERC1155} from "@rari-capital/solmate/src/tokens/ERC1155.sol";

/// @title Transfer
/// @author Fractional Art
/// @notice Target contract for transferring fungible and non-fungible tokens
contract Transfer {
    /// @notice Transfers ERC20 tokens
    /// @param _token Token contract
    /// @param _to Target address
    /// @param _value Transfer amount
    function ERC20Transfer(
        ERC20 _token,
        address _to,
        uint256 _value
    ) external {
        _token.transfer(_to, _value);
    }

    /// @notice Transfers ERC721 tokens
    /// @param _nft NFT contract
    /// @param _from Source address
    /// @param _to Target address
    /// @param _tokenId ID of the token
    function ERC721TransferFrom(
        ERC721 _nft,
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        _nft.safeTransferFrom(_from, _to, _tokenId);
    }

    /// @notice Transfers ERC1155 tokens
    /// @param _nft NFT contract
    /// @param _from Source address
    /// @param _to Target address
    /// @param _id ID of the token type
    /// @param _value Transfer amount
    /// @param _data Additional transaction data
    function ERC1155TransferFrom(
        ERC1155 _nft,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external {
        _nft.safeTransferFrom(_from, _to, _id, _value, _data);
    }

    /// @notice Batch transfers ERC1155 tokens
    /// @param _nft NFT contract
    /// @param _from Source address
    /// @param _to Target address
    /// @param _ids IDs of each token type
    /// @param _values Transfer amounts per token type
    /// @param _data Additional transaction data
    function ERC1155BatchTransferFrom(
        ERC1155 _nft,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external {
        _nft.safeBatchTransferFrom(_from, _to, _ids, _values, _data);
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address payable instance)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x41 + extraLength;
            uint256 runSize = creationSize - 10;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (10 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 61 runtime  | PUSH2 runtime (r)     | r                       | –
                mstore(
                    ptr,
                    0x6100000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x01), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0a
                // 3d          | RETURNDATASIZE        | 0 r                     | –
                // 81          | DUP2                  | r 0 r                   | –
                // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
                // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
                // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
                // f3          | RETURN                |                         | [0-runSize): runtime code

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME (55 bytes + extraLength)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 3d          | RETURNDATASIZE        | 0 0                     | –
                // 3d          | RETURNDATASIZE        | 0 0 0                   | –
                // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
                // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
                // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
                // 61          | PUSH2 extra           | extra 0 0 0 0           | [0, cds) = calldata
                mstore(
                    add(ptr, 0x03),
                    0x3d81600a3d39f33d3d3d3d363d3d376100000000000000000000000000000000
                )
                mstore(add(ptr, 0x13), shl(240, extraLength))

                // 60 0x37     | PUSH1 0x37            | 0x37 extra 0 0 0 0      | [0, cds) = calldata // 0x37 (55) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x37 extra 0 0 0 0  | [0, cds) = calldata
                // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x15),
                    0x6037363936610000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
                // 60 0x35     | PUSH1 0x35            | 0x35 sucess 0 rds       | [0, rds) = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
                // fd          | REVERT                | –                       | [0, rds) = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
                // f3          | RETURN                | –                       | [0, rds) = return data
                mstore(
                    add(ptr, 0x34),
                    0x5af43d3d93803e603557fd5bf300000000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x41;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Clone} from "clones-with-immutable-args/src/Clone.sol";
import {ERC1155, ERC1155TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC1155.sol";
import {FERC1155Error} from "./reverts/FERC1155Error.sol";

/// @title Vault
/// @author Fractional Art
/// @notice An ERC-1155 implementation for Fractions
contract FERC1155 is Clone, ERC1155 {
    /// @notice Name of the token contract
    string public constant NAME = "FERC1155";

    /// @notice URI of contract metadata
    string public contractURI;
    /// @notice Mapping of token type approvals owner => operator => tokenId => approved
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public isApproved;
    /// @notice Mapping of metadata contracts for token types id => metadata address
    mapping(uint256 => address) public metadata;
    /// @notice Mapping to track account nonces for metadata txs owner => nonces
    mapping(address => uint256) public nonces;
    /// @notice Mapping to track total supply for token types id => totalSupply
    mapping(uint256 => uint256) public totalSupply;

    /// @notice address that can deploy new vaults for this collection, manage metadata, etc
    address internal _controller;

    /// @notice Mapping to track royalty receivers for token types id => royaltyAddress
    mapping(uint256 => address) private royaltyAddress;
    /// @notice Mapping to track the royalty percent for token types id => royaltyPercent
    mapping(uint256 => uint256) private royaltyPercent;

    /// @notice Event log for minting an amount of a token type
    /// @param _owner Address of the owner of the token type
    /// @param _id Id of the token type
    /// @param _amount Number of fractions minted
    event MintFractions(address indexed _owner, uint256 _id, uint256 _amount);

    /// @notice Event log for burning an amount of a token type
    /// @param _owner Address of the owner of the token type
    /// @param _id Id of the token type
    /// @param _amount Number of fractions burned
    event BurnFractions(address indexed _owner, uint256 _id, uint256 _amount);

    /// @notice Event log for updating the Controller of the token contract
    /// @param _newController Address of the controller
    event ControllerTransferred(address indexed _newController);

    /// @notice Event log for approving a spender of a token type
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id Id of the token type
    /// @param _approved Approval status for the token type
    event SingleApproval(
        address indexed _owner,
        address indexed _operator,
        uint256 _id,
        bool _approved
    );

    /// @notice Event log for updating the metadata contract for a token type
    /// @param _metadata Address of the metadata contract that URI data is stored on
    /// @param _id Id of the token type
    event SetMetadata(address indexed _metadata, uint256 _id);

    /// @notice Event log for updating the royalty of a token type
    /// @param _receiver Address of the receiver of secondary sale royalties
    /// @param _id Id of the token type
    /// @param _percentage Royalty percent on secondary sales
    event SetRoyalty(
        address indexed _receiver,
        uint256 _id,
        uint256 _percentage
    );

    /// @notice Modifier for restricting function calls to the controller account
    modifier onlyController() {
        address controller_ = controller();
        if (msg.sender != controller_)
            revert FERC1155Error.InvalidSender(controller_, msg.sender);
        _;
    }

    /// @notice Modifier for restriction function calls to the VaultRegistry
    modifier onlyRegistry() {
        address vaultRegistry = VAULT_REGISTRY();
        if (msg.sender != vaultRegistry)
            revert FERC1155Error.InvalidSender(vaultRegistry, msg.sender);
        _;
    }

    /// @notice Mints new fractions for an Id
    /// @param _from Address to burn fraction tokens from
    /// @param _id Token Id to burn
    /// @param _amount Number of tokens to burn
    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external onlyRegistry {
        _burn(_from, _id, _amount);
        totalSupply[_id] -= _amount;
        emit BurnFractions(_from, _id, _amount);
    }

    /// @notice Hook to emit the URI update when setting the metadata or updating
    /// @param _id Token id metadata was updated for
    /// @param _uri URI of metadata
    function emitSetURI(uint256 _id, string memory _uri) external {
        if (msg.sender != metadata[_id])
            revert FERC1155Error.InvalidSender(metadata[_id], msg.sender);
        emit URI(_uri, _id);
    }

    /// @notice Mints new fractions for an Id
    /// @param _to Address to mint fraction tokens to
    /// @param _id Token Id to mint
    /// @param _amount Number of tokens to mint
    /// @param _data Extra calldata to include in the mint
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external onlyRegistry {
        _mint(_to, _id, _amount, _data);
        totalSupply[_id] += _amount;
        emit MintFractions(_to, _id, _amount);
    }

    /// @notice Permit function that approves an operator for token type with a valid sigature
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id Id of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    /// @param _v Signature data
    /// @param _r Signature data
    /// @param _s Signature data
    function permit(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (block.timestamp > _deadline)
            revert FERC1155Error.SignatureExpired(block.timestamp, _deadline);

        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 digest = _computeDigest(
                _owner,
                _operator,
                _id,
                _approved,
                _deadline
            );

            address signer = ecrecover(digest, _v, _r, _s);

            if (signer == address(0) || signer != _owner)
                revert FERC1155Error.InvalidSignature(signer, _owner);
        }

        isApproved[_owner][_operator][_id] = _approved;

        emit SingleApproval(_owner, _operator, _id, _approved);
    }

    /// @notice Permit function that approves an operator for token type with a valid sigature
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    /// @param _v Signature data
    /// @param _r Signature data
    /// @param _s Signature data
    function permitAll(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (block.timestamp > _deadline)
            revert FERC1155Error.SignatureExpired(block.timestamp, _deadline);

        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)"
                            ),
                            _owner,
                            _operator,
                            _approved,
                            nonces[_owner]++,
                            _deadline
                        )
                    )
                )
            );

            address signer = ecrecover(digest, _v, _r, _s);

            if (signer == address(0) || signer != _owner)
                revert FERC1155Error.InvalidSignature(signer, _owner);
        }

        isApprovedForAll[_owner][_operator] = _approved;

        emit ApprovalForAll(_owner, _operator, _approved);
    }

    /// @notice Scoped approvals allow us eliminate some of the risks associated with setting the approval for an entire collection
    /// @param _operator Address of spender account
    /// @param _id Id of the token type
    /// @param _approved Approval status for operator(spender) account
    function setApprovalFor(
        address _operator,
        uint256 _id,
        bool _approved
    ) external {
        isApproved[msg.sender][_operator][_id] = _approved;

        emit SingleApproval(msg.sender, _operator, _id, _approved);
    }

    /// @notice Sets the contract metadata
    /// @param _uri URI of metadata
    function setContractURI(string calldata _uri) external onlyController {
        contractURI = _uri;
    }

    /// @notice Sets the token metadata contract
    /// @param _metadata Address for metadata contract
    /// @param _id Token id to set the metadata for
    function setMetadata(address _metadata, uint256 _id)
        external
        onlyController
    {
        metadata[_id] = _metadata;
        emit SetMetadata(_metadata, _id);
    }

    /// @notice Sets the token royalties
    /// @param _id Token id royalties are being update for
    /// @param _receiver Address to receive royalties
    /// @param _percentage Percentage of royalties on secondary sales
    function setRoyalties(
        uint256 _id,
        address _receiver,
        uint256 _percentage
    ) external onlyController {
        royaltyAddress[_id] = _receiver;
        royaltyPercent[_id] = _percentage;
        emit SetRoyalty(_receiver, _id, _percentage);
    }

    /// @notice Updates the controller address for the FERC1155 token contract
    /// @param _newController Address of new controlling entity
    function transferController(address _newController)
        external
        onlyController
    {
        if (_newController == address(0)) revert FERC1155Error.ZeroAddress();
        _controller = _newController;
        emit ControllerTransferred(_newController);
    }

    /// @notice Sets the token royalties
    /// @param _id Token id royalties are being update for
    /// @param _salePrice Sale price to calculate the royalty for
    function royaltyInfo(uint256 _id, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyAddress[_id];

        // This sets percentages by price * percentage / 100
        royaltyAmount = (_salePrice * royaltyPercent[_id]) / 100;
    }

    /// @notice Transfer an amount of a token type between two accounts
    /// @param _from Source address for an amount of tokens
    /// @param _to Destination address for an amount of tokens
    /// @param _id Id of the token type
    /// @param _amount The amount of tokens being transferred
    /// @param _data Additional calldata
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public override {
        require(
            msg.sender == _from ||
                isApprovedForAll[_from][msg.sender] ||
                isApproved[_from][msg.sender][_id],
            "NOT_AUTHORIZED"
        );

        balanceOf[_from][_id] -= _amount;
        balanceOf[_to][_id] += _amount;

        emit TransferSingle(msg.sender, _from, _to, _id, _amount);

        require(
            _to.code.length == 0
                ? _to != address(0)
                : ERC1155TokenReceiver(_to).onERC1155Received(
                    msg.sender,
                    _from,
                    _id,
                    _amount,
                    _data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @notice Getter for controller account
    function controller() public view returns (address controllerAddress) {
        _controller == address(0)
            ? controllerAddress = INITIAL_CONTROLLER()
            : controllerAddress = _controller;
    }

    /// @notice Gets precomputed domain separator of recalculates
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID()
                ? INITIAL_DOMAIN_SEPARATOR()
                : _computeDomainSeparator();
    }

    /// @notice Getter for chain id immutable argument stored in calldata
    function INITIAL_CHAIN_ID() public pure returns (uint256) {
        return _getArgUint256(0);
    }

    /// @notice Getter for domain separator immutable argument stored in calldata
    function INITIAL_DOMAIN_SEPARATOR() public pure returns (bytes32) {
        return _getArgBytes32(32);
    }

    /// @notice Getter for initial controller account immutable argument stored in calldata
    function INITIAL_CONTROLLER() public pure returns (address) {
        return _getArgAddress(64);
    }

    /// @notice Getter for URI of a token type
    /// @param _id Id of the token type
    function uri(uint256 _id) public view override returns (string memory) {
        require(metadata[_id] != address(0), "NO METADATA");
        return ERC1155(metadata[_id]).uri(_id);
    }

    /// @notice VaultRegistry address that is allowed to call mint() and burn()
    function VAULT_REGISTRY() public pure returns (address) {
        return _getArgAddress(84);
    }

    /// @notice Computes digest for a signature
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id Id of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    function _computeDigest(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline
    ) internal returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address operator,uint256 tokenId,bool approved,uint256 nonce,uint256 deadline)"
                            ),
                            _owner,
                            _operator,
                            _id,
                            _approved,
                            nonces[_owner]++,
                            _deadline
                        )
                    )
                )
            );
    }

    /// @notice Computes domain separator
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(NAME)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import {ERC1155, FERC1155, FERC1155Error} from "../FERC1155.sol";

/// @title Metadata
/// @author Fractional Art
/// @notice Utility contract for storing metadata of an FERC1155 token
contract Metadata is ERC1155 {
    /// @notice FERC1155 token contract
    FERC1155 immutable token;
    /// @dev Mapping of ID type to URI of metadata
    mapping(uint256 => string) private tokenMetadata;

    /// @notice Initializes token contract
    constructor(FERC1155 _token) {
        token = _token;
    }

    /// @notice Gets the metadata of a token ID type
    /// @param _id ID of the token type
    /// @return URI of the token metadata
    function uri(uint256 _id) public view override returns (string memory) {
        return tokenMetadata[_id];
    }

    /// @notice Sets the metadata of a given token ID type
    /// @dev Can only be set by the token controller
    /// @param _uri URI of the token metadata
    /// @param _id ID of the token type
    function setURI(uint256 _id, string memory _uri) external {
        if (msg.sender != token.controller())
            revert FERC1155Error.InvalidSender({
                required: token.controller(),
                provided: msg.sender
            });

        tokenMetadata[_id] = _uri;
        FERC1155(token).emitSetURI(_id, _uri);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library RegistryError {
    /// @notice Emitted when the caller is not the controller.
    error NotController(address _controller, address _sender);

    /// @notice Emitted when the caller is not a vault.
    error NotVault(address _sender);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Create2ClonesWithImmutableArgs} from "clones-with-immutable-args/src/Create2ClonesWithImmutableArgs.sol";
import {Vault} from "./Vault.sol";

/// @title Vault Factory
/// @author Fractional Art
/// @notice Factory contract for deploying fractional vaults
contract VaultFactory {
    /// @dev Use clones library for address types
    using Create2ClonesWithImmutableArgs for address;
    /// @notice Vault proxy contract
    Vault public implementation;
    /// @dev Internal mapping to track the next seed to be used by an EOA
    mapping(address => bytes32) internal nextSeeds;

    /// @notice Event log for deploying vault
    /// @param _origin Address of transaction origin
    /// @param _deployer Address of sender
    /// @param _owner Address of vault owner
    /// @param _seed Value of seed
    /// @param _salt Value of salt
    /// @param _vault Address of deployed vault
    event DeployVault(
        address indexed _origin,
        address indexed _deployer,
        address indexed _owner,
        bytes32 _seed,
        bytes32 _salt,
        address _vault
    );

    /// @notice Initializes implementation contract
    constructor() {
        implementation = new Vault();
    }

    /// @notice Deploys new vault for sender
    /// @return vault Address of deployed vault
    function deploy() external returns (address payable vault) {
        vault = deployFor(msg.sender);
    }

    /// @notice Gets pre-computed address of vault deployed by given account
    /// @param _deployer Address of vault deployer
    /// @return vault Address of next vault
    function getNextAddress(address _deployer)
        external
        view
        returns (address vault)
    {
        bytes32 salt = keccak256(abi.encode(_deployer, nextSeeds[_deployer]));
        (uint256 creationPtr, uint256 creationSize) = address(implementation)
            .cloneCreationCode(abi.encodePacked());

        bytes32 creationHash;
        assembly {
            creationHash := keccak256(creationPtr, creationSize)
        }
        bytes32 data = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, creationHash)
        );
        vault = address(uint160(uint256(data)));
    }

    /// @notice Gets next seed value of given account
    /// @param _deployer Address of vault deployer
    /// @return nextSeed Value of next seed
    function getNextSeed(address _deployer) external view returns (bytes32) {
        return nextSeeds[_deployer];
    }

    /// @notice Deploys new vault for given address
    /// @param _owner Address of vault owner
    /// @return vault Address of deployed vault
    function deployFor(address _owner) public returns (address payable vault) {
        bytes32 seed = nextSeeds[tx.origin];

        // Prevent front-running the salt by hashing the concatenation of tx.origin and the user-provided seed.
        bytes32 salt = keccak256(abi.encode(tx.origin, seed));

        bytes memory data = abi.encodePacked();
        vault = address(implementation).clone(salt, data);
        Vault(vault).init();

        // Transfer the ownership from this factory contract to the specified owner.
        Vault(vault).transferOwnership(_owner);

        // Increment the seed.
        unchecked {
            nextSeeds[tx.origin] = bytes32(uint256(seed) + 1);
        }

        // Log the vault via en event.
        emit DeployVault(
            tx.origin,
            msg.sender,
            _owner,
            seed,
            salt,
            address(vault)
        );
    }
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type bytes32
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgBytes32(uint256 argOffset)
        internal
        pure
        returns (bytes32 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
        returns (uint256[] memory arr)
    {
        uint256 offset = _getImmutableArgsOffset();
        uint256 el;
        arr = new uint256[](arrLen);
        for (uint64 i = 0; i < arrLen; i++) {
            assembly {
                // solhint-disable-next-line no-inline-assembly
                el := calldataload(add(add(offset, argOffset), mul(i, 32)))
            }
            arr[i] = el;
        }
        return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library FERC1155Error {
    /// @notice Required sender is not sender
    error InvalidSender(address required, address provided);
    /// @notice Deadline for signature has passed
    error SignatureExpired(uint256 timestamp, uint256 deadline);
    /// @notice Fails signature validation
    error InvalidSignature(address signer, address owner);
    /// @notice Checks for address(0)
    error ZeroAddress();
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library Create2ClonesWithImmutableArgs {
    error CreateFail();

    function cloneCreationCode(address implementation, bytes memory data)
        internal
        pure
        returns (uint256 ptr, uint256 creationSize)
    {
        // unchecked is safe because it is unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            creationSize = 0x43 + extraLength;
            uint256 runSize = creationSize - 11;
            uint256 dataPtr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (11 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 61 runtime  | PUSH2 runtime (r)     | r 0                     | –
                mstore(
                    ptr,
                    0x3d61000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x02), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0b
                // 80          | DUP1                  | r r 0                   | –
                // 60 creation | PUSH1 creation (c)    | c r r 0                 | –
                // 3d          | RETURNDATASIZE        | 0 c r r 0               | –
                // 39          | CODECOPY              | r 0                     | [0-2d]: runtime code
                // 81          | DUP2                  | 0 c  0                  | [0-2d]: runtime code
                // f3          | RETURN                | 0                       | [0-2d]: runtime code
                mstore(
                    add(ptr, 0x04),
                    0x80600b3d3981f300000000000000000000000000000000000000000000000000
                )

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME
                // -------------------------------------------------------------------------------------------------------------

                // 36          | CALLDATASIZE          | cds                     | –
                // 3d          | RETURNDATASIZE        | 0 cds                   | –
                // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
                // 37          | CALLDATACOPY          | –                       | [0, cds] = calldata
                // 61          | PUSH2 extra           | extra                   | [0, cds] = calldata
                mstore(
                    add(ptr, 0x0b),
                    0x363d3d3761000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x10), shl(240, extraLength))

                // 60 0x38     | PUSH1 0x38            | 0x38 extra              | [0, cds] = calldata // 0x38 (56) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x38 extra          | [0, cds] = calldata
                // 39          | CODECOPY              | _                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0                     | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0 0                   | [0, cds] = calldata
                // 36          | CALLDATASIZE          | cds 0 0 0               | [0, cds] = calldata
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0         | [0, cds] = calldata
                mstore(
                    add(ptr, 0x12),
                    0x603836393d3d3d36610000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0         | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0             | [0, cds] = calldata
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0        | [0, cds] = calldata
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0    | [0, cds] = calldata
                // f4          | DELEGATECALL          | success 0               | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | rds success 0           | [0, cds] = calldata
                // 82          | DUP3                  | 0 rds success 0         | [0, cds] = calldata
                // 80          | DUP1                  | 0 0 rds success 0       | [0, cds] = calldata
                // 3e          | RETURNDATACOPY        | success 0               | [0, rds] = return data (there might be some irrelevant leftovers in memory [rds, cds] when rds < cds)
                // 90          | SWAP1                 | 0 success               | [0, rds] = return data
                // 3d          | RETURNDATASIZE        | rds 0 success           | [0, rds] = return data
                // 91          | SWAP2                 | success 0 rds           | [0, rds] = return data
                // 60 0x36     | PUSH1 0x36            | 0x36 sucess 0 rds       | [0, rds] = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds] = return data
                // fd          | REVERT                | –                       | [0, rds] = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds] = return data
                // f3          | RETURN                | –                       | [0, rds] = return data

                mstore(
                    add(ptr, 0x34),
                    0x5af43d82803e903d91603657fd5bf30000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr;
            assembly {
                copyPtr := add(ptr, 0x43)
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
        }
    }

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) external returns (address payable instance) {
        (uint256 creationPtr, uint256 creationSize) = cloneCreationCode(
            implementation,
            data
        );

        // solhint-disable-next-line no-inline-assembly
        assembly {
            instance := create2(0, creationPtr, creationSize, salt)
        }

        // if the create failed, the instance address won't be set
        if (instance == address(0)) {
            revert CreateFail();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {VaultError} from "./reverts/VaultError.sol";

/// @title Vault
/// @author Fractional Art
/// @notice Proxy contract for storing fractionalized assets
contract Vault {
    /// @notice Address of vault owner
    address public owner;
    /// @notice Merkle root hash of vault permissions
    bytes32 public merkleRoot;
    /// @notice Initializer value
    uint256 public nonce;
    /// @dev Minimum reserve of gas units
    uint256 private constant MIN_GAS_RESERVE = 5_000;
    /// @notice Mapping of function selector to plugin address
    mapping(bytes4 => address) public methods;

    /// @notice Event log for executing transactions
    /// @param _target Address of target contract
    /// @param _data Transaction data being executed
    /// @param _response Return data of delegatecall
    event Execute(address indexed _target, bytes _data, bytes _response);
    /// @notice Event log for transferring ownership
    /// @param _oldOwner Address of old owner
    /// @param _newOwner Address of new owner
    event TransferOwnership(
        address indexed _oldOwner,
        address indexed _newOwner
    );

    /// @notice Event log for installing plugins
    /// @param _selectors List of function selectors
    /// @param _plugins List of plugin contracts
    event InstallPlugin(bytes4[] _selectors, address[] _plugins);
    /// @notice Event log for uninstalling plugins
    /// @param _selectors List of function selectors
    event UninstallPlugin(bytes4[] _selectors);

    /// @notice Initializes nonce and proxy owner
    function init() external {
        if (nonce != 0) revert VaultError.Initialized(owner, msg.sender, nonce);
        nonce = 1;
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    /// @dev Callback for receiving Ether when the calldata is empty
    receive() external payable {}

    /// @notice Callback for handling plugin transactions
    /// @param _data Transaction data
    /// @return response Return data from executing plugin
    // prettier-ignore
    fallback(bytes calldata _data) external payable returns (bytes memory response) {
        address plugin = methods[msg.sig];
        (,response) = _execute(plugin, _data);
    }

    /// @notice Executes vault transactions through delegatecall
    /// @param _target Target address
    /// @param _data Transaction data
    /// @param _proof Merkle proof of permission hash
    /// @return success Result status of delegatecall
    /// @return response Return data of delegatecall
    function execute(
        address _target,
        bytes calldata _data,
        bytes32[] calldata _proof
    ) external payable returns (bool success, bytes memory response) {
        bytes4 selector;
        assembly {
            selector := calldataload(_data.offset)
        }

        // Generate leaf node by hashing module, target and function selector.
        bytes32 leaf = keccak256(abi.encode(msg.sender, _target, selector));
        // Check that the caller is either a module with permission to call or the owner.
        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
            if (msg.sender != owner)
                revert VaultError.NotAuthorized(msg.sender, _target, selector);
        }

        (success, response) = _execute(_target, _data);
    }

    /// @notice Installs plugin by setting function selector to contract address
    /// @param _selectors List of function selectors
    /// @param _plugins Addresses of plugin contracts
    function install(bytes4[] memory _selectors, address[] memory _plugins)
        external
    {
        if (owner != msg.sender) revert VaultError.NotOwner(owner, msg.sender);
        uint256 length = _selectors.length;
        for (uint256 i = 0; i < length; i++) {
            methods[_selectors[i]] = _plugins[i];
        }
        emit InstallPlugin(_selectors, _plugins);
    }

    /// @notice Uninstalls plugin by setting function selector to zero address
    /// @param _selectors List of function selectors
    function uninstall(bytes4[] memory _selectors) external {
        if (owner != msg.sender) revert VaultError.NotOwner(owner, msg.sender);
        uint256 length = _selectors.length;
        for (uint256 i = 0; i < length; i++) {
            methods[_selectors[i]] = address(0);
        }
        emit UninstallPlugin(_selectors);
    }

    /// @notice Sets merkle root of vault permissions
    /// @param _rootHash Hash of merkle root
    function setMerkleRoot(bytes32 _rootHash) external {
        if (owner != msg.sender) revert VaultError.NotOwner(owner, msg.sender);
        merkleRoot = _rootHash;
    }

    /// @notice Transfers ownership to given account
    /// @param _newOwner Address of new owner
    function transferOwnership(address _newOwner) external {
        if (owner != msg.sender) revert VaultError.NotOwner(owner, msg.sender);
        owner = _newOwner;
        emit TransferOwnership(msg.sender, _newOwner);
    }

    /// @notice Executes plugin transactions through delegatecall
    /// @param _target Target address
    /// @param _data Transaction data
    /// @return success Result status of delegatecall
    /// @return response Return data of delegatecall
    function _execute(address _target, bytes calldata _data)
        internal
        returns (bool success, bytes memory response)
    {
        // Check that the target is a valid contract.
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_target)
        }
        if (codeSize == 0) revert VaultError.TargetInvalid(_target);
        // Save the owner address in memory. This local variable cannot be modified during the DELEGATECALL.
        address owner_ = owner;
        // Reserve some gas to ensure that the function has enough to finish the execution.
        uint256 stipend = gasleft() - MIN_GAS_RESERVE;

        // Delegate call to the target contract.
        (success, response) = _target.delegatecall{gas: stipend}(_data);
        if (owner_ != owner) revert VaultError.OwnerChanged(owner_, owner);

        if (!success) {
            if (response.length == 0) revert VaultError.ExecutionReverted();
            _revertedWithReason(response);
        }
    }

    /// @notice Reverts transaction with reason
    function _revertedWithReason(bytes memory _response) internal pure {
        assembly {
            let returndata_size := mload(_response)
            revert(add(32, _response), returndata_size)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library VaultError {
    /// @notice Emitted when execution reverted with no reason.
    error ExecutionReverted();

    /// @notice Emitted when ownership of the proxy has been renounced (ownership transferred to address(0))
    /// and a user tries to reinitialize the owner.
    error Initialized(address _owner, address _newOwner, uint256 _nonce);

    /// @notice Emitted when there is no implementation stored in methods for a function signature
    error MethodNotFound();

    /// @notice Emitted when the caller is not the owner.
    error NotAuthorized(address _caller, address _target, bytes4 _selector);

    /// @notice Emitted when the caller is not the owner.
    error NotOwner(address _owner, address _caller);

    /// @notice Emitted when the owner is changed during the DELEGATECALL.
    error OwnerChanged(address _originalOwner, address _newOwner);

    /// @notice Emitted when passing an EOA or an undeployed contract as the target.
    error TargetInvalid(address _target);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}