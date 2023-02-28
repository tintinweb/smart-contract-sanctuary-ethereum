// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

//SPDX-License-Identifier: MIT
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/** 
 * @dev @brougkr
 * - Launchpad is an interface to easily create a NFT project on ETH. Optionally including Dutch Auction, LiveMint, And Mint Pass Capabilities
 * - It Interacts With The Following Contracts Optionally, Depending On Your Project Needs:
 * - { 1 } - { Marketplace }
 * - { 2 } - { LiveMint }
 * - { 3 } - { ArtBlocks Core Engine / Flex }
 * - { 4 } - { Minted Works Factory }
 * - { 5 } - { MintPass Factory }
 * - { 6 } - { ERC20 Factory }
*/
pragma solidity 0.8.17;
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
contract Launchpad is Ownable, ReentrancyGuard
{   
    struct StateParameters
    {
        bool _Active;
        address _Marketplace;
        address _LiveMint;
        address _ArtBlocksCore;
        address _ArtBlocksFlex;
        address _FactoryMintedWorks;
        address _FactoryMintPass;
        address _FactoryERC20;
        address _LaunchpadRegistry;
    }

    StateParameters public Params = StateParameters (
        true,                                       // _Active
        0xe745243b82ebC46E5c23d9B1B968612c65d45f3d, // _Marketplace
        0xe745243b82ebC46E5c23d9B1B968612c65d45f3d, // _LiveMint
        0xe745243b82ebC46E5c23d9B1B968612c65d45f3d, // _ArtBlocksCoreEngine
        0xe745243b82ebC46E5c23d9B1B968612c65d45f3d, // _ArtBlocksCoreFlex
        0xe745243b82ebC46E5c23d9B1B968612c65d45f3d, // _FactoryMintPass
        0xe745243b82ebC46E5c23d9B1B968612c65d45f3d, // _FactoryMintedWorks
        0xe745243b82ebC46E5c23d9B1B968612c65d45f3d, // _FactoryERC20
        0xe745243b82ebC46E5c23d9B1B968612c65d45f3d  // _LaunchpadRegistry
    );

    mapping(address=>bool) public Operator;
    mapping(address=>bool) public Admin;

    event ProjectInvoked(uint Index);
    event ProjectModified(uint Index);
    event LiveMintEnabled(uint Index);

    constructor() { Operator[msg.sender] = true; }
    
    /**
     * @dev Enables Live Minting For A Project
     */
    function EnableLiveMinting(uint LaunchpadProjectID) external onlyOperator nonReentrant
    {
        require(Params._Active, "Launchpad: Not Active");
        uint ArtBlocksProjectID = ILaunchpadRegistry(Params._LaunchpadRegistry).ReadProjectID(LaunchpadProjectID);
        IMinter(Params._ArtBlocksCore).updateProjectArtistAddress(ArtBlocksProjectID, Params._LiveMint);
        emit LiveMintEnabled(LaunchpadProjectID);
    }

    /**
     * @dev Starts An ArtBlocks Project
     */
    function InitArtBlocksEngineProject (
        IMintPass.Params memory ParamsMintPass,       // Mint Pass Parameters
        IMinter.ParamsArtBlocks memory ParamsMint,    // Minted Work Parameters
        IMarketplace.Sale memory ParamsSale,          // Marketplace Sale Parameters
        IMarketplace.State memory ParamsSaleInternal, // Marketplace Sale State Parameters
        bytes32[] calldata RootsPriority,
        bytes32[] calldata RootsAmounts,
        uint[] calldata DiscountAmounts
    ) external onlyOperator nonReentrant {
        require(Params._Active, "Launchpad: Not Active");
        uint ArtBlocksProjectID = 69420;
        // uint ArtBlocksProjectID = ViewNextABProjectID();
        // IMinter(Params._ArtBlocksCore).addProject(ParamsMint._Name, ParamsMint._ArtistAddress, 1 ether);
        // IMinter(Params._ArtBlocksCore).updateProjectArtistAddress(ArtBlocksProjectID, address(this));
        // IMinter(Params._ArtBlocksCore).updateProjectCurrencyInfo(ArtBlocksProjectID, "BRTMP", Params._FactoryERC20);
        // IMinter(Params._ArtBlocksCore).toggleProjectIsActive(ArtBlocksProjectID);
        uint MintPassProjectID = IMintPass(Params._FactoryMintPass).__InitMintPass(ParamsMintPass);
        ParamsSale._ProjectIDMintPass = MintPassProjectID;
        IMarketplace(Params._Marketplace).__StartSale(ParamsSale, ParamsSaleInternal, RootsPriority, RootsAmounts, DiscountAmounts);
        uint LiveMintArtistID = ILiveMint(Params._LiveMint).__InitLiveMint(
            ILiveMint.Params(
                Params._FactoryMintPass, 
                Params._ArtBlocksCore, 
                address(0), 
                ParamsMintPass._MaxSupply, 
                MintPassProjectID,
                ArtBlocksProjectID
            )
        );
        ILaunchpadRegistry(Params._LaunchpadRegistry).__NewProject(ILaunchpadRegistry.Project (
            ParamsMint._Name,            // _Name
            true,                        // _Active
            true,                        // _ArtBlocks
            ArtBlocksProjectID,          // _ArtBlocksProjectID
            LiveMintArtistID,            // _LiveMintArtistID
            ParamsMintPass._MaxSupply,   // _MaxSupply
            ParamsMintPass._MintPacks,   // _MintPacks
            "ArtBlocks",                 // _MetadataMintedWork
            ParamsMintPass._MetadataURI, // _MetadataMintPass
            Params._FactoryMintPass,     // _MintPassAddress
            Params._ArtBlocksCore        // _MintedWorkAddress
        ));
    }

    /**
     * @dev Starts An ArtBlocks Project
     */
    function InitArtBlocksPolyProject (
        IMintPass.Params memory ParamsMintPass,       // Mint Pass Parameters
        IMinter.ParamsArtBlocks memory ParamsMint,    // Minted Work Parameters
        IMarketplace.Sale memory ParamsSale,          // Marketplace Sale Parameters
        IMarketplace.State memory ParamsSaleInternal, // Marketplace Sale State Parameters
        bytes32[] calldata RootsPriority,
        bytes32[] calldata RootsAmounts,
        uint[] calldata DiscountAmounts
    ) external onlyOperator nonReentrant {
        require(Params._Active, "Launchpad: Not Active");
        uint ArtBlocksProjectID = 69420;
        // uint ArtBlocksProjectID = ViewNextABProjectID();
        // IMinter(Params._ArtBlocksCore).addProject(ParamsMint._Name, ParamsMint._ArtistAddress, 1 ether);
        // IMinter(Params._ArtBlocksCore).updateProjectArtistAddress(ArtBlocksProjectID, address(this));
        // IMinter(Params._ArtBlocksCore).updateProjectCurrencyInfo(ArtBlocksProjectID, "BRTMP", Params._FactoryERC20);
        // IMinter(Params._ArtBlocksCore).toggleProjectIsActive(ArtBlocksProjectID);
        uint MintPassProjectID = IMintPass(Params._FactoryMintPass).__InitMintPass(ParamsMintPass);
        ParamsSale._ProjectIDMintPass = MintPassProjectID;
        IMarketplace(Params._Marketplace).__StartSale(ParamsSale, ParamsSaleInternal, RootsPriority, RootsAmounts, DiscountAmounts);
        uint LiveMintArtistID = ILiveMint(Params._LiveMint).__InitLiveMint(
            ILiveMint.Params(
                Params._FactoryMintPass, 
                Params._ArtBlocksCore, 
                address(0), 
                ParamsMintPass._MaxSupply, 
                MintPassProjectID,
                ArtBlocksProjectID
            )
        );
        ILaunchpadRegistry(Params._LaunchpadRegistry).__NewProject(ILaunchpadRegistry.Project (
            ParamsMint._Name,            // _Name
            true,                        // _Active
            true,                        // _ArtBlocks
            ArtBlocksProjectID,          // _ArtBlocksProjectID
            LiveMintArtistID,            // _LiveMintArtistID
            ParamsMintPass._MaxSupply,   // _MaxSupply
            ParamsMintPass._MintPacks,   // _MintPacks
            "ArtBlocks",                 // _MetadataMintedWork
            ParamsMintPass._MetadataURI, // _MetadataMintPass
            Params._FactoryMintPass,     // _MintPassAddress
            Params._ArtBlocksCore        // _MintedWorkAddress
        ));
    }

    /**
     * @dev Initializes A Non ArtBlocks Project
     */
    function InitProject (
        IMintPass.Params memory ParamsMintPass,     // Mint Pass Parameters
        IMinter.ParamsCustom memory ParamsCustom,   // Minted Work Parameters
        ILiveMint.Params memory ParamsLiveMint,     // LiveMint Parameters 
        IMarketplace.Sale memory ParamsSale, // Marketplace Parameters
        IMarketplace.State memory ParamsSaleInternal,      // Marketplace Parameters Cont.
        bytes32[] calldata RootsPriority,
        bytes32[] calldata RootsAmounts,
        uint[] calldata DiscountAmounts
    ) external onlyOperator nonReentrant {
        require(Params._Active, "Launchpad: Not Active");
        ParamsMintPass._ArtBlocksProjectID = 69420;
        uint LiveMintArtistID = ILiveMint(Params._LiveMint).__InitLiveMint(ParamsLiveMint);                     
        IMarketplace(Params._Marketplace).__StartSale(ParamsSale, ParamsSaleInternal, RootsPriority, RootsAmounts, DiscountAmounts); // done
        IMintPass(Params._FactoryMintPass).__InitMintPass(ParamsMintPass); // done
        IMinter(Params._FactoryMintedWorks).__addProject(ParamsCustom); // random edition
        ILaunchpadRegistry(Params._LaunchpadRegistry).__NewProject(ILaunchpadRegistry.Project (
            ParamsCustom._Name,                 // _Name
            true,                               // _Active
            false,                              // _ArtBlocks
            ParamsMintPass._ArtBlocksProjectID, // _ArtBlocksProjectID note: (not used for non AB projects)
            LiveMintArtistID,                   // _LiveMintArtistID
            ParamsMintPass._MaxSupply,          // _MaxSupply
            ParamsMintPass._MintPacks,          // _MintPacks
            ParamsMintPass._MetadataURI,        // _MetadataMintPass
            ParamsCustom._MetadataMintedWork,   // _MetadataMintedWork
            Params._FactoryMintPass,            // _MintPassAddress
            Params._FactoryMintedWorks          // _MintedWorkAddress
        ));
    }

    /**
     * @dev Starts A Sale And Instantiates New MintPass Project
     */
    function StartSale(       
        IMintPass.Params memory ParamsMintPass,       // Mint Pass Parameters
        IMarketplace.Sale memory ParamsSale,          // Marketplace Parameters
        IMarketplace.State memory ParamsSaleInternal, // Marketplace Parameters Cont.
        bytes32[] calldata RootsPriority,
        bytes32[] calldata RootsAmounts,
        uint[] calldata DiscountAmounts
    ) external onlyOperator nonReentrant {
        uint MintPassProjectID = IMintPass(Params._FactoryMintPass).__InitMintPass(ParamsMintPass); // done
        ParamsSale._ProjectIDMintPass = MintPassProjectID; // done
        IMarketplace(Params._Marketplace).__StartSale(ParamsSale, ParamsSaleInternal, RootsPriority, RootsAmounts, DiscountAmounts); // done
    }



    /**
     * @dev Returns Next ProjectID From ArtBlocks Contract
     */
    function ViewNextABProjectID() public view returns(uint) { return ArtBlocksCore(Params._ArtBlocksCore).nextProjectId(); }

    /**
     * @dev Adds An Operator
     */
    function _OperatorAdd(address Wallet) external onlyAdmin { Operator[Wallet] = true; }

    /**
     * @dev Removes An Operator
     */
    function _OperatorRemove(address Wallet) external onlyAdmin { Operator[Wallet] = false; }
    
    /**
     * @dev Changes ArtBlocks Core Address
     */
    function __ChangeArtBlocksCore(address NewAddress) external onlyOwner { Params._ArtBlocksCore = NewAddress; }

    /**
     * @dev Changes Marketplace Address
     */
    function __ChangeMarketplace(address NewAddress) external onlyOwner { Params._Marketplace = NewAddress; }

    /**
     * @dev Changes LiveMint Address
     */
    function __ChangeLiveMint(address NewAddress) external onlyOwner { Params._LiveMint = NewAddress; }

    /**
     * @dev Changes Mint Pass Factory Address
     */
    function __ChangeFactoryMintPass(address NewAddress) external onlyOwner { Params._FactoryMintPass = NewAddress; }
    
    /**
     * @dev Changes Minted Works Factory Address
     */
    function __ChangeFactoryMintedWorks(address NewAddress) external onlyOwner { Params._FactoryMintedWorks = NewAddress; }

    /**
     * @dev Initiates Upgrade Of The Launchpad
     */
    function __InitiateUpgrade(address NewLaunchpadAddress) external onlyOwner
    {
        ICustom(Params._Marketplace).__NewLaunchpadAddress(NewLaunchpadAddress);
        ICustom(Params._LiveMint).__NewLaunchpadAddress(NewLaunchpadAddress);
        ICustom(Params._FactoryMintedWorks).__NewLaunchpadAddress(NewLaunchpadAddress);
        ICustom(Params._FactoryMintPass).__NewLaunchpadAddress(NewLaunchpadAddress);
        ICustom(Params._FactoryERC20).__NewLaunchpadAddress(NewLaunchpadAddress);
        ICustom(Params._LaunchpadRegistry).__NewLaunchpadAddress(NewLaunchpadAddress);
    }

    /**
     * @dev Instantiates A New State
     */
    function __NewState(StateParameters memory _State) external onlyOwner { Params = _State; }

    /**
     * @dev Toggles The Contract State
     */
    function __ActiveToggle() external onlyOwner { Params._Active = !Params._Active; }

    /**
     * @dev Adds An Admin
     */
    function __AdminAdd(address Wallet) external onlyOwner { Admin[Wallet] = true; }

    /**
     * @dev Removes An Admin
     */
    function __AdminRemove(address Wallet) external onlyOwner { Admin[Wallet] = false; }


    /**
     * @dev Executes Arbitrary Transaction(s)
     */
    function __InitTransaction(address[] memory Targets, uint[] memory Values, bytes[] memory Datas) external onlyOwner
    {
        for (uint x; x < Targets.length; x++) 
        {
            (bool success,) = Targets[x].call{value:(Values[x])}(Datas[x]);
            require(success, "i have failed u anakin");
        }
    }

    /**
     * @dev Operator Access Control
     */
    modifier onlyOperator
    {
        require(Operator[msg.sender], "onlyOperator: `msg.sender` Is Not Operator");
        _;
    }

    modifier onlyAdmin
    {
        require(Admin[msg.sender], "onlyAdmin: `msg.sender` Is Not Admin");
        _;
    }
}

/**
 * @dev Interface For The Live Mint Smart Contract
 */
interface ILiveMint
{
    struct Params
    {
        address _MintPass;        // _MintPass
        address _Minter;          // _Minter
        address _PolyptychSource; // _PolyptychSource
        uint _MaxSupply;          // _MaxSupply
        uint _MintPassProjectID;  // _MintPassProjectID
        uint _ArtBlocksProjectID; // _ArtBlocksProjectID 
    }
    function __InitLiveMint(Params memory) external returns (uint);
}

/**
 * @dev Interface For The Marketplace Smart Contract
 */
interface IMarketplace 
{ 
    struct Sale
    {
        string _Name;                     // [0] -> _Name
        uint _ProjectIDMintPass;          // [1] -> _ProjectIDMintPass
        uint _ProjectIDArtBlocks;         // [2] -> _ProjectIDArtBlocks
        uint _PriceStart;                 // [2] -> _PriceStart
        uint _PriceEnd;                   // [3] -> _PriceEnd
        uint _WalletLimiter;              // [4] -> _WalletLimiter
        uint _MaximumAvailableForSale;    // [5] -> _MaximumAvailableForSale
        uint _StartingBlockUnixTimestamp; // [6] -> _StartingBlockUnixTimestamp
        uint _SecondsBetweenPriceDecay;   // [7] -> _SecondsBetweenPriceDecay
        uint _SaleStrip;                  // [8] -> _SaleStrip note: For Traditional MintPack transferFrom() Sales 
    }

    struct State
    {
        address _NFT;           // [0] -> _NFT
        address _Operator;      // [1] _Operator (Wallet That NFT Is Pulling From)
        uint _CurrentIndex;     // [2] _CurrentIndex (If Simple Sale Type, This Is The Next Token Index To Iterate Upon)
        uint _Type;             // [3] _SaleType (0 = Simple, 1 = TransferFrom, 2 = PurchaseTo, 3 = MintPack)
        bool _ActivePublic;     // [7] -> _ActivePublic
        bool _ActiveBrightList; // [8] -> _ActiveBrightList 
        bool _Discount;         // [9] -> _Discount
        bool _ActiveRespend;    // [10] -> _ActiveRespend
    }

    function __StartSale(Sale memory _Sale, State memory _State, bytes32[] calldata RootsPrioriy, bytes32[] calldata RootsAmounts, uint[] calldata DiscountAmounts) external;
}

/**
 * @dev Interface For Mint Pass Factory
 */
interface IMintPass
{
    struct Params
    {
        uint _MaxSupply;
        uint _MintPacks;
        uint _ArtistIDs;
        uint _ArtBlocksProjectID;
        uint _Reserve;
        string _MetadataURI;
    }
    function __InitMintPass(Params memory) external returns (uint _MintPassID);
}

/**
 * @dev Interface For Minted Works, Either ArtBlocks or Non-ArtBlocks
 */
interface IMinter 
{ 
    struct ParamsCustom
    {
        string _Name;
        string _Symbol;
        string _MetadataMintedWork;
    }

    /**
     * @dev Paramters For Minted Work
     */
    struct ParamsArtBlocks
    {
        string _Name;
        address _ArtistAddress;
    }

    /**
     * @dev ArtBlocks Add Project
     */
    function addProject(string calldata Name, address ArtistAddress, uint PricePerTokenInWei) external;

    /**
     * @dev ArtBlocks Toggle Project Active
     */
    function toggleProjectIsActive(uint ProjectID) external;

    /**
     * @dev Custom Add Project
     */
    function __addProject(ParamsCustom memory) external;

    /**
     * @dev Updates Project Artist Address
     */
    function updateProjectArtistAddress(uint ProjectID, address ArtistAddress) external;

    /**
     * @dev Updates Project Currency Info
     */
    function updateProjectCurrencyInfo(uint ProjectID, string memory CurrencySymbol, address ERC20) external;
}

interface ILaunchpadRegistry
{
    struct Project
    {
        string _Name;
        bool _Active;
        bool _ArtBlocks;
        uint _ArtBlocksProjectID;
        uint _LiveMintArtistID;
        uint _MaxSupply;
        uint _MintPacks;
        string _MetadataMintPass;
        string _MetadataMintedWork;
        address _MintPassAddress;
        address _MintedWorkAddress;
    }
    function __NewProject(Project memory) external;

    function ReadProjectID(uint ProjectID) external view returns(uint);
}

interface IERC20Factory
{
    function __InitERC20(string calldata Name, string calldata Symbol, uint MaxSupply) external returns(address);
}

/**
 * @dev Interface To Upgrade The Launchpad Contract
 */
interface ICustom { function __NewLaunchpadAddress(address NewAddress) external; }

/**
 * @dev Abstract Contract To Recieve The Next ProjectID From ArtBlocks
 */
abstract contract ArtBlocksCore { uint public nextProjectId; }