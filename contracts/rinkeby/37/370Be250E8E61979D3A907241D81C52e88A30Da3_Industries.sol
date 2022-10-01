// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./01_Validators.sol";

contract Industries is Ownable  {
    using SafeERC20 for IERC20;

    uint immutable _cores_version;
    uint256 public constant MAX_DURABILITY = 1000;

    IERC20 public _Mechadium;
    Validators public _Validators;

    struct Industry {
        address _owner;
        uint256 _type;
        uint256 _biome;
    }

    struct Land {
        uint256 _id;
        uint256 _biome;
        Industry _industry;
    }

    // @dev land_id => Land_struct{}
    mapping( uint256 => Land ) private _lands;

    // @dev land_id => owner_address
    mapping( uint256 => address ) private _landOwner;

    // @dev owner_address => land_ids[]
    mapping( address => uint256[] ) private _landsOwned;

    // @dev part_id => if is broken
    mapping ( uint256 => uint256 ) public _breakingLoad;

    constructor( uint _version, IERC20 __Mechadium, Validators __Validators ){
        _cores_version = _version;
        _Mechadium = __Mechadium;
        _Validators = __Validators;
    }

    event CreatePart(
        string item,
        address indexed owner,
        uint256 arena_id
    );

    event DestroyPart(
        string item,
        address indexed from,
        uint256 arena_id,
        uint256 amount
    );

    event BrokePart(
        string item,
        uint256 part_id
    );

    event RepairPart(
        string item,
        uint256 part_id
    );

    event GenesysLand(
        address to,
        uint256 biome,
        uint256 land_id
    );

    function isBroken( uint256 part_id ) public view virtual returns ( bool ) {
        return bool( _breakingLoad[ part_id ] == 0 );
    }

    function getBreakingLoad( uint256 part_id ) public view virtual returns ( uint256 ) {
        return _breakingLoad[ part_id ];
    }

    function updateBreakingLoad( uint256 part_id, uint256 erosion ) public virtual {
        _breakingLoad[ part_id ] -= erosion;
    }

    function getLand( uint256 land_id ) public view virtual returns ( Land memory ) {
        return _lands[ land_id ];
    }

    function getLandOwner( uint256 land_id ) public view virtual returns ( address ) {
        return _landOwner[ land_id ];
    }

    function getOwnedLandIds( address owner ) public view virtual returns ( uint256[] memory ) {
        return _landsOwned[ owner ];
    }

    function getOwnedLands( address owner ) public view virtual returns ( Land[] memory ) {
        uint256[] memory landsIDs = _landsOwned[ owner ];
        Land[] memory ownedLands = new Land[]( landsIDs.length );
        for ( uint256 i = 0; i < landsIDs.length; i++ ){
            ownedLands[i] = _lands[ landsIDs[i] ];
        }
        return ownedLands;
    }

    function validateLand( uint256 land_id ) public virtual onlyOwner {
        _Validators.addLand( land_id );
    }

    function validateArena( uint256 arena_id ) public virtual onlyOwner {
        _Validators.addArena( arena_id );
    }

    function validateHelmet( uint256 helmet_id ) public virtual onlyOwner {
        _Validators.addHelmet( helmet_id );
    }

    function validateNexus( uint256 nexus_id ) public virtual onlyOwner {
        _Validators.addNexus( nexus_id );
    }

    function validateCore( uint256 core_id ) public virtual onlyOwner {
        _Validators.addCore( core_id );
    }

    function validateWeapon( uint256 weapon_id ) public virtual onlyOwner {
        _Validators.addWeapon( weapon_id );
    }

    function validateAccessory( uint256 accessory_id ) public virtual onlyOwner {
        _Validators.addAccessory( accessory_id );
    }

    function validateMotion( uint256 motion_id ) public virtual onlyOwner {
        _Validators.addMotion( motion_id );
    }

    function invalidateLand( uint256 land_id ) public virtual onlyOwner {
        _Validators.removeLand( land_id );
    }

    function invalidateArena( uint256 arena_id ) public virtual onlyOwner {
        _Validators.removeArena( arena_id );
    }

    function invalidateHelmet( uint256 helmet_id ) public virtual onlyOwner {
        _Validators.removeHelmet( helmet_id );
    }

    function invalidateNexus( uint256 nexus_id ) public virtual onlyOwner {
        _Validators.removeNexus( nexus_id );
    }

    function invalidateCore( uint256 core_id ) public virtual onlyOwner {
        _Validators.removeCore( core_id );
    }

    function invalidateWeapon( uint256 weapon_id ) public virtual onlyOwner {
        _Validators.removeWeapon( weapon_id );
    }

    function invalidateAccessory( uint256 accessory_id ) public virtual onlyOwner {
        _Validators.removeAccessory( accessory_id );
    }

    function invalidateMotion( uint256 motion_id ) public virtual onlyOwner {
        _Validators.removeMotion( motion_id );
    }

    function createPart( address to, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();
        nft_1155.mint( to, amount );
    }

    function createParts( address to, uint256[] memory amounts ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();
        nft_1155.mintBatch( to, amounts );
    }

    function createLand( address to, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        uint256 land_id = nft_1155.tokenID();
        createPart( to, amount );
        validateLand( land_id );

        emit CreatePart( "Land", to, land_id );
    }

    function createLands( address to, uint256[] memory amounts ) public virtual onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) createLand( to, amounts[i] );
    }

    function createArena( address to, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        uint256 arena_id = nft_1155.tokenID();
        createPart( to, amount );
        validateArena( arena_id );

        emit CreatePart( "Arena", to, arena_id );
    }

    function createArenas( address to, uint256[] memory amounts ) public virtual onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) createArena( to, amounts[i] );
    }

    function createHelmet( address to, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        uint256 helmet_id = nft_1155.tokenID();
        createPart( to, amount );
        validateHelmet( helmet_id );

        emit CreatePart( "Helmet", to, helmet_id );
    }

    function createHelmets( address to, uint256[] memory amounts ) public virtual onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) createHelmet( to, amounts[i] );
    }

    function createNexus( address to, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        uint256 nexus_id = nft_1155.tokenID();
        createPart( to, amount );
        validateNexus( nexus_id );

        emit CreatePart( "Nexus", to, nexus_id );
    }

    function createNexuses( address to, uint256[] memory amounts ) public virtual onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) createNexus( to, amounts[i] );
    }

    function createCore( address to, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        uint256 core_id = nft_1155.tokenID();
        createPart( to, amount );
        validateCore( core_id );
        _breakingLoad[ core_id ] = MAX_DURABILITY;

        emit CreatePart( "Core", to, core_id );
    }

    function createCores( address to, uint256[] memory amounts ) public virtual onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) createCore( to, amounts[i] );
    }

    function createWeapon( address to, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        uint256 weapon_id = nft_1155.tokenID();
        createPart( to, amount );
        validateWeapon( weapon_id );
        _breakingLoad[ weapon_id ] = MAX_DURABILITY;

        emit CreatePart( "Weapon", to, weapon_id );
    }

    function createWeapons( address to, uint256[] memory amounts ) public virtual onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) createWeapon( to, amounts[i] );
    }

    function createAccessory( address to, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        uint256 accessory_id = nft_1155.tokenID();
        createPart( to, amount );
        validateAccessory( accessory_id );
        _breakingLoad[ accessory_id ] = MAX_DURABILITY;

        emit CreatePart( "Accessory", to, accessory_id );
    }

    function createAccessories( address to, uint256[] memory amounts ) public virtual onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) createAccessory( to, amounts[i] );
    }

    function createMotion( address to, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        uint256 motion_id = nft_1155.tokenID();
        createPart( to, amount );
        validateMotion( motion_id );
        _breakingLoad[ motion_id ] = MAX_DURABILITY;

        emit CreatePart( "Motion", to, motion_id );
    }

    function createMotions( address to, uint256[] memory amounts ) public virtual onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) createMotion( to, amounts[i] );
    }

    function destroyPart( address from, uint256 part_id, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();
        nft_1155.burn( from, part_id, amount );
    }

    function destroyLand( address from, uint256 land_id, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        require( _Validators.isValidLand( land_id ), "Provided land_id is not valid" );
        destroyPart( from, land_id, amount );

        // Check if is NFT and then invalidate part
        if( nft_1155.isNotFungible( land_id )) invalidateLand( land_id );

        emit DestroyPart( "Land", from, land_id, amount );
    }

    function destroyLands( address from, uint256[] memory land_ids, uint256[] memory amounts ) public virtual onlyOwner {

        require( land_ids.length == amounts.length, "Number of Lands and amounts mismatch" );
        for (uint256 i = 0; i < amounts.length; i++) destroyLand( from, land_ids[i], amounts[i] );
    }

    function destroyArena( address from, uint256 arena_id, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        require( _Validators.isValidArena( arena_id ), "Provided arena_id is not valid" );
        destroyPart( from, arena_id, amount );

        // Check if is NFT and then invalidate part
        if( nft_1155.isNotFungible( arena_id )) invalidateArena( arena_id );

        emit DestroyPart( "Arena", from, arena_id, amount );
    }

    function destroyArenas( address from, uint256[] memory arena_ids, uint256[] memory amounts ) public virtual onlyOwner {

        require( arena_ids.length == amounts.length, "Number of Arena and amounts mismatch" );
        for (uint256 i = 0; i < amounts.length; i++) destroyArena( from, arena_ids[i], amounts[i] );
    }

    function destroyHelmet( address from, uint256 helmet_id, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        require( _Validators.isValidHelmet( helmet_id ), "Provided helmet_id is not valid" );
        destroyPart( from, helmet_id, amount );

        // Check if is NFT and then invalidate part
        if( nft_1155.isNotFungible( helmet_id )) invalidateHelmet( helmet_id );

        emit DestroyPart( "Helmet", from, helmet_id, amount );
    }

    function destroyHelmets( address from, uint256[] memory helmet_ids, uint256[] memory amounts ) public virtual onlyOwner {

        require( helmet_ids.length == amounts.length, "Number of Helmet and amounts mismatch" );
        for (uint256 i = 0; i < amounts.length; i++) destroyHelmet( from, helmet_ids[i], amounts[i] );
    }

    function destroyNexus( address from, uint256 nexus_id, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        require( _Validators.isValidNexus( nexus_id ), "Provided nexus_id is not valid" );
        destroyPart( from, nexus_id, amount );

        // Check if is NFT and then invalidate part
        if( nft_1155.isNotFungible( nexus_id )) invalidateNexus( nexus_id );

        emit DestroyPart( "Nexus", from, nexus_id, amount );
    }

    function destroyNexuses( address from, uint256[] memory nexus_ids, uint256[] memory amounts ) public virtual onlyOwner {

        require( nexus_ids.length == amounts.length, "Number of Nexus and amounts mismatch" );
        for (uint256 i = 0; i < amounts.length; i++) destroyNexus( from, nexus_ids[i], amounts[i] );
    }

    function destroyCore( address from, uint256 core_id, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        require( _Validators.isValidCore( core_id ), "Provided core_id is not valid" );
        destroyPart( from, core_id, amount );

        // Check if is NFT and then invalidate part
        if( nft_1155.isNotFungible( core_id )) invalidateCore( core_id );

        emit DestroyPart( "Core", from, core_id, amount );
    }

    function destroyCores( address from, uint256[] memory core_ids, uint256[] memory amounts ) public virtual onlyOwner {

        require( core_ids.length == amounts.length, "Number of Core and amounts mismatch" );
        for (uint256 i = 0; i < amounts.length; i++) destroyCore( from, core_ids[i], amounts[i] );
    }

    function destroyWeapon( address from, uint256 weapon_id, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        require( _Validators.isValidWeapon( weapon_id ), "Provided weapon_id is not valid" );
        destroyPart( from, weapon_id, amount );

        // Check if is NFT and then invalidate part
        if( nft_1155.isNotFungible( weapon_id )) invalidateWeapon( weapon_id );

        emit DestroyPart( "Weapon", from, weapon_id, amount );
    }

    function destroyWeapons( address from, uint256[] memory weapon_ids, uint256[] memory amounts ) public virtual onlyOwner {

        require( weapon_ids.length == amounts.length, "Number of Weapon and amounts mismatch" );
        for (uint256 i = 0; i < amounts.length; i++) destroyWeapon( from, weapon_ids[i], amounts[i] );
    }

    function destroyAccessory( address from, uint256 accessory_id, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        require( _Validators.isValidAccessory( accessory_id ), "Provided accessory_id is not valid" );
        destroyPart( from, accessory_id, amount );

        // Check if is NFT and then invalidate part
        if( nft_1155.isNotFungible( accessory_id )) invalidateAccessory( accessory_id );

        emit DestroyPart( "Accessory", from, accessory_id, amount );
    }

    function destroyAccessories( address from, uint256[] memory accessory_ids, uint256[] memory amounts ) public virtual onlyOwner {

        require( accessory_ids.length == amounts.length, "Number of Accessory and amounts mismatch" );
        for (uint256 i = 0; i < amounts.length; i++) destroyAccessory( from, accessory_ids[i], amounts[i] );
    }

    function destroyMotion( address from, uint256 motion_id, uint256 amount ) public virtual onlyOwner {
        NFT_1155 nft_1155 = _Validators._NFT_1155();

        require( _Validators.isValidMotion( motion_id ), "Provided motion_id is not valid" );
        destroyPart( from, motion_id, amount );

        // Check if is NFT and then invalidate part
        if( nft_1155.isNotFungible( motion_id )) invalidateMotion( motion_id );

        emit DestroyPart( "Motion", from, motion_id, amount );
    }

    function destroyMotions( address from, uint256[] memory motion_ids, uint256[] memory amounts ) public virtual onlyOwner {

        require( motion_ids.length == amounts.length, "Number of Motion and amounts mismatch" );
        for (uint256 i = 0; i < amounts.length; i++) destroyMotion( from, motion_ids[i], amounts[i] );
    }

    function genesysLand( address to, uint256 land_id ) public virtual {

        NFT_1155 nft_1155 = _Validators._NFT_1155();

        require( msg.sender == to || nft_1155.isApprovedForAll( to, msg.sender ), "Caller is not owner nor approved");
        require( _Validators.isValidLand( land_id ), "Provided land_id is not a valid Land");

        _lands[ land_id ] = Land ({
            _id: land_id,
            _biome: 0,
            _industry: Industry({
                _owner: address(0x0),
                _type: 0,
                _biome:0
            })
        });

        // TODO test this solution
        if( _landOwner[ land_id ] != address(0x0) ) nft_1155.pop( _landsOwned[ _landOwner[ land_id ] ], land_id );

        _landOwner[ land_id ] = to;
        _landsOwned[ to ].push( land_id );

        emit GenesysLand( to, _lands[ land_id ]._biome ,land_id );
    }

    // TODO IMPLEMENT PAYABLE Helmets fusion => Forge( helmet_ids[] ) returns helmet_id

    // TODO IMPLEMENT PAYABLE Mechas reforging => Factory( mecha_ids[] )

    // TODO IMPLEMENT PAYABLE Parts crafting from resources => Atelier()

    // TODO IMPLEMENT PAYABLE Parts repair => Hangar( part_ids[] )

    // TODO IMPLEMENT PAYABLE Resources staking => Hunting lodge()
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./00_NFT_1155.sol";


contract Validators is Ownable{

    uint immutable _validator_version;

    NFT_1155 public _NFT_1155;

    // Core Validators Keys
    uint8 constant public WEAPON_KEY = 0;
    uint8 constant public ACCESSORY_KEY = 1;
    uint8 constant public MOTION_KEY = 2;

    // Cores Type Keys
    uint8 constant public CORE_TYPE_C1_KEY = 1;
    uint8 constant public CORE_TYPE_C2_KEY = 2;
    uint8 constant public CORE_TYPE_C3_KEY = 3;
    uint8 constant public CORE_TYPE_C4_KEY = 4;
    uint8 constant public CORE_TYPE_C5_KEY = 5;
    uint8 constant public CORE_TYPE_C6_KEY = 6;
    uint8 constant public CORE_TYPE_C7_KEY = 7;

    // Cores Type Sizes
    uint8[3] public CORE_TYPE_C1 = [1,0,0];
    uint8[3] public CORE_TYPE_C2 = [0,1,0];
    uint8[3] public CORE_TYPE_C3 = [1,0,1];
    uint8[3] public CORE_TYPE_C4 = [1,1,1];
    uint8[3] public CORE_TYPE_C5 = [0,1,1];
    uint8[3] public CORE_TYPE_C6 = [0,2,1];
    uint8[3] public CORE_TYPE_C7 = [2,0,1];

    // @dev land_id => if is valid
    mapping( uint256 => bool ) private land_ids;

    // @dev arena_id => if is valid
    mapping( uint256 => bool ) private arena_ids;

    // @dev nexus_id => if is valid
    mapping( uint256 => bool ) private nexus_ids;

    // @dev helmet_id => if is valid
    mapping( uint256 => bool ) private helmet_ids;

    // @dev core_id => if is valid
    mapping( uint256 => bool ) private core_ids;

    // @dev weapon_id => if is valid
    mapping( uint256 => bool ) private weapon_ids;

    // @dev accessory_id => if is valid
    mapping( uint256 => bool ) private accessory_ids;

    // @dev motion_id => if is valid
    mapping( uint256 => bool ) private motion_ids;

    constructor( uint _version, NFT_1155 __NFT_1155 ) {
        _validator_version = _version;
        _NFT_1155 = __NFT_1155;
    }

    event AddToValidator(
        string item,
        uint256 id
    );

    event RemoveFromValidator(
        string item,
        uint256 id
    );

    // TODO IMPLEMENT: getMigrationData()

    function isValidLand( uint256 land_id ) public view virtual returns ( bool ) {
        return land_ids[ land_id ];
    }

    function isValidArena( uint256 arena_id ) public view virtual returns ( bool ) {
        return arena_ids[ arena_id ];
    }

    function isValidHelmet( uint256 helmet_id ) public view virtual returns ( bool ) {
        return helmet_ids[ helmet_id ];
    }

    function isValidNexus( uint256 nexus_id ) public view virtual returns ( bool ) {
        return nexus_ids[ nexus_id ];
    }

    function isValidCore( uint256 core_id ) public view virtual returns ( bool ) {
        return core_ids[ core_id ];
    }

    function isValidWeapon( uint256 weapon_id ) public view virtual returns ( bool ) {
        return weapon_ids[ weapon_id ];
    }

    function isValidAccessory( uint256 accessory_id ) public view virtual returns ( bool ) {
        return accessory_ids[ accessory_id ];
    }

    function isValidMotion( uint256 motion_id ) public view virtual returns ( bool ) {
        return motion_ids[ motion_id ];
    }

    function addLand( uint256 land_id ) public virtual onlyOwner {
        require( !land_ids[ land_id ], "This Land is already added to Land validator" );
        land_ids[ land_id ] = true;

        emit AddToValidator( "Land", land_id );
    }

    function addArena( uint256 arena_id ) public virtual onlyOwner {
        require( !arena_ids[ arena_id ], "This Arena is already added to Arena validator" );
        arena_ids[ arena_id ] = true;

        emit AddToValidator( "Arena", arena_id );
    }

    function addHelmet( uint256 helmet_id ) public virtual onlyOwner {
        require( !helmet_ids[ helmet_id ], "This Helmet is already added to Helmet validator" );
        helmet_ids[ helmet_id ] = true;

        emit AddToValidator( "Helmet", helmet_id );
    }

    function addNexus( uint256 nexus_id ) public virtual onlyOwner {
        require( !nexus_ids[ nexus_id ], "This Nexus is already added to Nexus validator" );
        nexus_ids[ nexus_id ] = true;

        emit AddToValidator( "Nexus", nexus_id );
    }

    function addCore( uint256 core_id ) public virtual onlyOwner {
        require( !core_ids[ core_id ], "This Core is already added to Core validator" );
        core_ids[ core_id ] = true;

        emit AddToValidator( "Core", core_id );
    }

    function addWeapon( uint256 weapon_id ) public virtual onlyOwner {
        require( !weapon_ids[ weapon_id ], "This Weapon is already added to Weapon validator" );
        weapon_ids[ weapon_id ] = true;

        emit AddToValidator( "Weapon", weapon_id );
    }

    function addAccessory( uint256 accessory_id ) public virtual onlyOwner {
        require( !accessory_ids[ accessory_id ], "This Accessory is already added to Accessory validator" );
        accessory_ids[ accessory_id ] = true;

        emit AddToValidator( "Accessory", accessory_id );
    }

    function addMotion( uint256 motion_id ) public virtual onlyOwner {
        require( !motion_ids[ motion_id ], "This Motion is already added to Motion validator" );
        motion_ids[ motion_id ] = true;

        emit AddToValidator( "Motion", motion_id );
    }

    function removeLand( uint256 land_id ) public virtual onlyOwner {
        require( land_ids[ land_id ], "This Land is already removed from Land validator" );
        land_ids[ land_id ] = false;

        emit RemoveFromValidator("Land", land_id );
    }

    function removeArena ( uint256 arena_id ) public virtual onlyOwner {
        require( arena_ids[ arena_id ], "This Arena is already removed from Arena validator" );
        arena_ids[ arena_id ] = false;

        emit RemoveFromValidator("Arena", arena_id );
    }

    function removeHelmet ( uint256 helmet_id ) public virtual onlyOwner {
        require( helmet_ids[ helmet_id ], "This Helmet is already removed from Helmet validator" );
        helmet_ids[ helmet_id ] = false;

        emit RemoveFromValidator("Helmet", helmet_id );
    }

    function removeNexus ( uint256 nexus_id ) public virtual onlyOwner {
        require( nexus_ids[ nexus_id ], "This Nexus is already removed from Nexus validator" );
        nexus_ids[ nexus_id ] = false;

        emit RemoveFromValidator("Nexus", nexus_id );
    }

    function removeCore ( uint256 core_id ) public virtual onlyOwner {
        require( core_ids[ core_id ], "This Core is already removed from Core validator" );
        core_ids[ core_id ] = false;

        emit RemoveFromValidator("Core", core_id );
    }

    function removeWeapon( uint256 weapon_id ) public virtual onlyOwner {
        require( weapon_ids[ weapon_id ], "This Weapon is already removed from Weapon validator" );
        weapon_ids[ weapon_id ] = false;

        emit RemoveFromValidator("Weapon", weapon_id );
    }

    function removeAccessory( uint256 accessory_id ) public virtual onlyOwner {
        require( accessory_ids[ accessory_id ], "This Accessory is already removed from Accessory validator" );
        accessory_ids[ accessory_id ] = false;

        emit RemoveFromValidator("Accessory", accessory_id );
    }

    function removeMotion ( uint256 motion_id ) public virtual onlyOwner {
        require( motion_ids[ motion_id ], "This Motion is already removed from Motion validator" );
        motion_ids[ motion_id ] = false;

        emit RemoveFromValidator("Motion", motion_id );
    }

    function getValidSocketsSizes( uint8 core_type ) public view virtual returns ( uint8[3] memory ) {

        if( core_type == CORE_TYPE_C1_KEY ) return CORE_TYPE_C1;

        else if( core_type == CORE_TYPE_C2_KEY ) return CORE_TYPE_C2;

        else if( core_type == CORE_TYPE_C3_KEY ) return CORE_TYPE_C3;

        else if( core_type == CORE_TYPE_C4_KEY ) return CORE_TYPE_C4;

        else if( core_type == CORE_TYPE_C5_KEY ) return CORE_TYPE_C5;

        else if( core_type == CORE_TYPE_C6_KEY ) return CORE_TYPE_C6;

        else if( core_type == CORE_TYPE_C7_KEY ) return CORE_TYPE_C7;

        else revert( "Invalid core type parameter" );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract NFT_1155 is ERC1155, ERC1155URIStorage, ERC1155Supply, Ownable {

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Array of Active IDs
    uint256[] private _active;

    // Mapping from <owner_address> to <owned_ids_array>
    mapping(address => uint256[]) private _owned;

    // Mapping for NFT from <token_id> to <owner_address>
    mapping(uint256 => address) private _owners;

    // Implementation of self incremental token ID
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    event ConvertToNonFungible( address indexed owner, uint256 id );

    constructor( string memory name_, string memory symbol_, string memory uri_ ) ERC1155( uri_ ) {
        _name = name_;
        _symbol = symbol_;
        _tokenIdCounter.reset();
        _tokenIdCounter.increment();
        ERC1155URIStorage._setBaseURI(uri_);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function tokenID() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getActiveIDs() public view virtual returns (uint256[] memory) {
        return _active;
    }

    function uri( uint256 tokenId ) public view virtual override( ERC1155, ERC1155URIStorage ) returns (string memory) {
        return ERC1155URIStorage.uri( tokenId );
    }

    function totalSupply( uint256 tokenId ) public view virtual override returns (uint256) {
        require( ERC1155Supply.exists( tokenId ), "NFT1155: supply query for nonexistent token" );
        return ERC1155Supply.totalSupply( tokenId );
    }

    function balanceOf( address account, uint256 tokenId ) public view virtual override returns (uint256) {
        require( ERC1155Supply.exists( tokenId ), "NFT1155: balance query for nonexistent token" );
        return ERC1155.balanceOf( account, tokenId );
    }

    function ownerOfNF( uint256 tokenId ) public view virtual returns (address) {
        require( ERC1155Supply.exists( tokenId ), "NFT1155: owner query for nonexistent token" );
        require( isNotFungible( tokenId ), "NFT1155: owner query for Fungible token" );
        return _owners[ tokenId ];
    }

    function getOwnedIDs( address owner ) public view virtual returns (uint256[] memory) {
        return _owned[ owner ];
    }

    function isNotFungible( uint256 tokenId ) public view returns (bool) {
        require( ERC1155Supply.exists( tokenId ), "NFT1155: is Non Fungible query for nonexistent token" );
        return bool( ERC1155Supply.totalSupply( tokenId ) == 1 );
    }

    function convertToNonFungible( address owner, uint256 tokenId ) public onlyOwner {
        require( ERC1155Supply.exists( tokenId ), "NFT1155: convert query for nonexistent token" );
        require( ! isNotFungible( tokenId ), "NFT1155: this token is already Non Fungible" );
        require( ERC1155.balanceOf( owner, tokenId ) > 0, "NFT1155: convert query from non owner" );

        burn( owner, tokenId, 1);
        mint( owner, 1 );
    }

    function mint( address to, uint256 amount ) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        require( amount > 0, "NFT1155: amount must be grater than 0");
        ERC1155._mint( to, tokenId, amount, new bytes(0) );
    }

    function mintBatch( address to, uint256[] memory amounts ) public onlyOwner {
        require( amounts.length >= 1 , "NFT1155: amounts length must be grater than or equal to 1" );
        uint256[] memory tokenIDs = new uint256[]( amounts.length );
        for (uint256 i = 0; i < amounts.length; i++) {
            require( amounts[i] > 0, "NFT1155: amount must be grater than 0");
            tokenIDs[i] = _tokenIdCounter.current();
            _tokenIdCounter.increment();
        }
        ERC1155._mintBatch( to, tokenIDs, amounts, new bytes(0) );
    }

    function burn( address from, uint256 tokenId, uint256 amount ) public onlyOwner {
        require( amount > 0, "NFT1155: amount must be grater than 0");
        ERC1155._burn( from, tokenId, amount);
    }

    function burnBatch( address from, uint256[] memory tokenIDs, uint256[] memory amounts ) public onlyOwner {
        for (uint256 i = 0; i < amounts.length; i++) require( amounts[i] > 0, "NFT1155: amount must be grater than 0");
        ERC1155._burnBatch( from, tokenIDs, amounts );
    }

    function transfer( address from, address to, uint256 tokenId, uint256 amount) public virtual {
        require( from == _msgSender() || ERC1155.isApprovedForAll(from, _msgSender()), "NFT1155: caller is not owner nor approved" );
        ERC1155._safeTransferFrom(from, to, tokenId, amount, new bytes(0));
    }

    function transferBatch( address from, address to, uint256[] memory tokenIDs, uint256[] memory amounts) public virtual {
        require( from == _msgSender() || ERC1155.isApprovedForAll(from, _msgSender()), "NFT1155: caller is not owner nor approved" );
        ERC1155._safeBatchTransferFrom(from, to, tokenIDs, amounts, new bytes(0));
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override( ERC1155, ERC1155Supply ) {

        // Set Token Supply during minting
        if ( from == address(0) ) ERC1155Supply._beforeTokenTransfer( operator, from, to, ids, amounts, data );

        for (uint256 i = 0; i < ids.length; ++i) {

            bool isNonFungible = ERC1155Supply.totalSupply( ids[i] ) == 1;

            // Minting case
            if ( from == address(0) ) {

                // Set token URI
                ERC1155URIStorage._setURI( ids[i], string( abi.encodePacked( "/", Strings.toString( ids[i] ) ) ) );

                // Add ID into _active
                _active.push( ids[i] );

                // Add ID into _owned
                _owned[ to ].push( ids[i] );

                // Set ownership for Non Fungible
                if ( isNonFungible ) _owners[ ids[i] ] = to;
            }
            else require( ERC1155Supply.exists( ids[i] ), "NFT1155: query for nonexistent token" );

            // Burning case
            if ( to == address(0) ){

                if ( amounts[i] == ERC1155Supply.totalSupply( ids[i] ) ){
                    // Reset token URI
                    ERC1155URIStorage._setURI( ids[i], "" );

                    // Remove ID from _active
                    _active = pop( _active, ids[i] );
                }

                // Remove ID _owned
                if ( amounts[i] == ERC1155.balanceOf( from, ids[i] ) ) _owned[ from ] = pop( _owned[ from ], ids[i] );

                // Remove ownership for Non Fungible
                if ( isNonFungible ) delete _owners[ ids[i] ];
            }

            // Transfer case
            if ( from != address(0) && to != address(0) ) {

                // Update ID into _owned
                _owned[ to ].push( ids[i] );
                if ( amounts[i] == ERC1155.balanceOf( from, ids[i] ) )_owned[ from ] = pop( _owned[ from ], ids[i] );

                // Update ownership for Non Fungible
                if ( isNonFungible )  _owners[ ids[i] ] = to;
            }
        }

        // Reset Token Supply during burning
        if ( to == address(0) ) ERC1155Supply._beforeTokenTransfer( operator, from, to, ids, amounts, data );
    }


    function pop( uint256[] memory array, uint256 element ) public virtual returns( uint256[] memory ){

        uint256[] memory poppedArray = new uint256[]( array.length - 1);
        uint x = 0;
        for (uint256 i = 0; i < array.length; i++ ) {
            if (array[i] != element) {
                poppedArray[x] = array[i];
                x++;
            }
        }
        return poppedArray;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155URIStorage.sol)

pragma solidity ^0.8.0;

import "../../../utils/Strings.sol";
import "../ERC1155.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 * Inspired by the ERC721URIStorage extension
 *
 * _Available since v4.6._
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using Strings for uint256;

    // Optional base URI
    string private _baseURI = "";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the concatenation of the `_baseURI`
     * and the token-specific uri if the latter is set
     *
     * This enables the following behaviors:
     *
     * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
     *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
     *   is empty per default);
     *
     * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
     *   which in most cases will contain `ERC1155._uri`;
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURI)) : super.uri(tokenId);
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
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