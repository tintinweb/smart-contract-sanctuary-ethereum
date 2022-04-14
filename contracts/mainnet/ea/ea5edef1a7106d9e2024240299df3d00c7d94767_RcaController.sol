/// SPDX-License-Identifier: UNLICENSED

/**

                               ................                            
                          ..',,;;::::::::ccccc:;,'..                       
                      ..',;;;;::::::::::::cccccllllc;..                    
                    .';;;;;;;,'..............',:clllolc,.                  
                  .,;;;;;,..                    .';cooool;.                
                .';;;;;'.           .....          .,coodoc.               
               .,;;;;'.       ..',;:::cccc:;,'.      .;odddl'              
              .,;;;;.       .,:cccclllllllllool:'      ,odddl'             
             .,:;:;.      .;ccccc:;,''''',;cooooo:.     ,odddc.            
             ';:::'     .,ccclc,..         .':odddc.    .cdddo,            
            .;:::,.     ,cccc;.              .:oddd:.    ,dddd:.           
            '::::'     .ccll:.                .ldddo'    'odddc.           
            ,::c:.     ,lllc'    .';;;::::::::codddd;    ,dxxxc.           
           .,ccc:.    .;lllc.    ,oooooddddddddddddd;    :dxxd:            
            ,cccc.     ;llll'    .;:ccccccccccccccc;.   'oxxxo'            
            'cccc,     'loooc.                         'lxxxd;             
            .:lll:.    .;ooooc.                      .;oxxxd:.             
             ,llll;.    .;ooddo:'.                ..:oxxxxo;.              
             .:llol,.     'coddddl:;''.........,;codxxxxd:.                
              .:lool;.     .':odddddddddoooodddxxxxxxdl;.                  
               .:ooooc'       .';codddddddxxxxxxdol:,.                     
                .;ldddoc'.        ...'',,;;;,,''..                         
                  .:oddddl:'.                          .,;:'.              
                    .:odddddoc;,...              ..',:ldxxxx;              
                      .,:odddddddoolcc::::::::cllodxxxxxxxd:.              
                         .';clddxxxxxxxxxxxxxxxxxxxxxxoc;'.                
                             ..',;:ccllooooooollc:;,'..                    
                                        ......                             
                                                                      
**/

pragma solidity 0.8.11;
import "../general/RcaGovernable.sol";
import "../library/MerkleProof.sol";
import "../interfaces/IRcaShield.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RCA Controller
 * @notice Controller contract for all RCA vaults.
 * This contract creates vaults, emits events when anything happens on a vault,
 * keeps track of variables relevant to vault functionality, keeps track of capacities,
 * amounts for sale on each vault, prices of tokens, and updates vaults when needed.
 * @author Robert M.C. Forster, Romke Jonker, Taek Lee, Chiranjibi Poudyal
 */

contract RcaController is RcaGovernable {
    /// @notice Address => whether or not it's a verified shield.
    mapping(address => bool) public shieldMapping;
    /// @notice Address => whether or not shield is active.
    mapping(address => bool) public activeShields;

    /// @notice Address => whether or not router is verified.
    mapping(address => bool) public isRouterVerified;

    /// @notice Fees for users per year for using the system. Ideally just 0 but option is here.
    /// In hundredths of %. 1000 == 10%.
    uint256 public apr;
    /// @notice Amount of time users must wait to withdraw tokens after requesting redemption. In seconds.
    uint256 public withdrawalDelay;
    /// @notice Discount for purchasing tokens being liquidated from a shield. 1000 == 10%.
    uint256 public discount;
    /// @notice Address that funds from selling tokens is sent to.
    address payable public treasury;
    /// @notice Amount of funds for sale on a protocol, sent in by DAO after a hack occurs (in token).
    bytes32 public liqForClaimsRoot;
    /// @notice The amount of each shield that's currently reserved for hack payouts. 1000 == 10%.
    bytes32 public reservedRoot;
    /// @notice Root of all underlying token prices--only used if the protocol is doing pricing. Price in Ether.
    bytes32 public priceRoot;

    /// @notice Nonce to prevent replays of capacity signatures. User => RCA nonce.
    mapping(address => uint256) public nonces;
    /// @notice Last time each individual shield was checked for update.
    mapping(address => uint256) public lastShieldUpdate;

    /**
     * @dev The update variable flow works in an interesting way to optimize efficiency:
     * Each time a user interacts with a specific shield vault, it calls Controller
     * for all necessary interactions (events & updates). The general Controller function
     * will check when when the last shield update was made vs. all recent other updates.
     * If a system update is more recent than the shield update, value is changed.
     */
    struct SystemUpdates {
        uint32 liqUpdate;
        uint32 reservedUpdate;
        uint32 withdrawalDelayUpdate;
        uint32 discountUpdate;
        uint32 aprUpdate;
        uint32 treasuryUpdate;
    }
    SystemUpdates public systemUpdates;

    /**
     * @dev Events are used to notify the frontend of events on shields. If we have 1,000 shields,
     * a centralized event system can tell the frontend which shields to check for a specific user.
     */
    event Mint(address indexed rcaShield, address indexed user, uint256 timestamp);
    event RedeemRequest(address indexed rcaShield, address indexed user, uint256 timestamp);
    event RedeemFinalize(address indexed rcaShield, address indexed user, uint256 timestamp);
    event Purchase(address indexed rcaShield, address indexed user, uint256 timestamp);
    event ShieldCreated(
        address indexed rcaShield,
        address indexed underlyingToken,
        string name,
        string symbol,
        uint256 timestamp
    );
    event ShieldCancelled(address indexed rcaShield);

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// modifiers //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Ensure the sender is a shield.
     * @dev We don't want non-shield contracts creating mint, redeem, purchase events.
     */
    modifier onlyShield() {
        require(shieldMapping[msg.sender], "Caller must be a Shield Vault.");
        _;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////// constructor /////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Construct with initial privileged addresses for controller.
     * @param _governor Complete control of the contracts. Can change all other owners.
     * @param _guardian Guardian multisig that can freeze percents after a hack.
     * @param _priceOracle Oracle that can submit price root to the ecosystem.
     * @param _capOracle Oracle that can submit capacity root to the ecosystem.
     * @param _apr Initial fees for the shield (1000 == 10%).
     * @param _discount Discount for purchasers of the token (1000 == 10%).
     * @param _withdrawalDelay Amount of time (in seconds) users must wait before withdrawing.
     * @param _treasury Address of the treasury that Ether funds will be sent to.
     */
    constructor(
        address _governor,
        address _guardian,
        address _priceOracle,
        address _capOracle,
        uint256 _apr,
        uint256 _discount,
        uint256 _withdrawalDelay,
        address payable _treasury
    ) {
        initRcaGovernable(_governor, _guardian, _capOracle, _priceOracle);

        apr = _apr;
        discount = _discount;
        treasury = _treasury;
        withdrawalDelay = _withdrawalDelay;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// onlyShield /////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Updates contract, emits event for minting, checks capacity.
     * @param _user User that is minting tokens.
     * @param _uAmount Underlying token amount being liquidated.
     * @param _expiry Time (Unix timestamp) that this request expires.
     * @param _v The recovery byte of the signature.
     * @param _r Half of the ECDSA signature pair.
     * @param _s Half of the ECDSA signature pair.
     * @param _newCumLiqForClaims New cumulative amount of liquidated tokens if an update is needed.
     * @param _liqForClaimsProof Merkle proof to verify the new cumulative liquidated if needed.
     */
    function mint(
        address _user,
        uint256 _uAmount,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof
    ) external onlyShield {
        _update(_newCumLiqForClaims, _liqForClaimsProof, 0, new bytes32[](0), false);

        // Confirm the capacity oracle approved this transaction.
        verifyCapacitySig(_user, _uAmount, _expiry, _v, _r, _s);

        emit Mint(msg.sender, _user, block.timestamp);
    }

    /**
     * @notice Updates contract, emits event for redeem action.
     * @param _user User that is redeeming tokens.
     * @param _newCumLiqForClaims New cumulative amount of liquidated tokens if an update is needed.
     * @param _liqForClaimsProof Merkle proof to verify the new cumulative liquidated if needed.
     * @param _newPercentReserved New percent of the shield that is reserved for hack payouts.
     * @param _percentReservedProof Merkle proof to verify the new percent reserved.
     */
    function redeemRequest(
        address _user,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof,
        uint256 _newPercentReserved,
        bytes32[] calldata _percentReservedProof
    ) external onlyShield {
        _update(_newCumLiqForClaims, _liqForClaimsProof, _newPercentReserved, _percentReservedProof, true);

        emit RedeemRequest(msg.sender, _user, block.timestamp);
    }

    /**
     * @notice Updates contract, emits event for redeem action, returns if router is verified.
     * @param _user User that is redeeming tokens.
     * @param _to Router address which should be used for zapping.
     * @param _newCumLiqForClaims New cumulative amount of liquidated tokens if an update is needed.
     * @param _liqForClaimsProof Merkle proof to verify the new cumulative liquidated if needed.
     * @param _newPercentReserved New percent of the shield that is reserved for hack payouts.
     * @param _percentReservedProof Merkle proof to verify the new percent reserved.
     */
    function redeemFinalize(
        address _user,
        address _to,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof,
        uint256 _newPercentReserved,
        bytes32[] calldata _percentReservedProof
    ) external onlyShield returns (bool) {
        _update(_newCumLiqForClaims, _liqForClaimsProof, _newPercentReserved, _percentReservedProof, true);

        emit RedeemFinalize(msg.sender, _user, block.timestamp);
        return isRouterVerified[_to];
    }

    /**
     * @notice Updates contract, emits event for purchase action, verifies price.
     * @param _user The user that is making the purchase.
     * @param _uToken The user that is making the purchase.
     * @param _ethPrice The price of one token in Ether.
     * @param _priceProof Merkle proof to verify the Ether price of the token.
     * @param _newCumLiqForClaims New cumulative amount of liquidated tokens if an update is needed.
     * @param _liqForClaimsProof Merkle proof to verify the new cumulative liquidated if needed.
     */
    function purchase(
        address _user,
        address _uToken,
        uint256 _ethPrice,
        bytes32[] calldata _priceProof,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof
    ) external onlyShield {
        _update(_newCumLiqForClaims, _liqForClaimsProof, 0, new bytes32[](0), false);

        verifyPrice(_uToken, _ethPrice, _priceProof);
        emit Purchase(msg.sender, _user, block.timestamp);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// internal //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice All general updating of shields for a variety of variables that could have changed
     * since the last interaction. Amount for sale, whether or not the system is paused, new
     * withdrawal delay, new discount for sales, new APR fee for general functionality.
     * @param _newCumLiqForClaims New cumulative amount of liquidated tokens if an update is needed.
     * @param _liqForClaimsProof Merkle proof to verify the new cumulative liquidated if needed.
     * @param _newPercentReserved New percent of tokens of this shield that are reserved.
     * @param _percentReservedProof Merkle proof to verify the new percent reserved.
     * @param _redeem Whether or not this is a redeem request to know whether to update reserved.
     */
    function _update(
        uint256 _newCumLiqForClaims,
        bytes32[] memory _liqForClaimsProof,
        uint256 _newPercentReserved,
        bytes32[] memory _percentReservedProof,
        bool _redeem
    ) internal {
        IRcaShield shield = IRcaShield(msg.sender);
        uint32 lastUpdate = uint32(lastShieldUpdate[msg.sender]);

        // Seems kinda messy but not too bad on gas.
        SystemUpdates memory updates = systemUpdates;

        if (lastUpdate <= updates.treasuryUpdate) shield.setTreasury(treasury);
        if (lastUpdate <= updates.discountUpdate) shield.setDiscount(discount);
        if (lastUpdate <= updates.withdrawalDelayUpdate) shield.setWithdrawalDelay(withdrawalDelay);
        // Update shield here to account for interim period where APR was changed but shield had not updated.
        if (lastUpdate <= updates.aprUpdate) {
            shield.controllerUpdate(apr, uint256(updates.aprUpdate));
            shield.setApr(apr);
        }
        if (lastUpdate <= updates.liqUpdate) {
            // Update potentially needed here as well if amtForSale will grow from APR.
            shield.controllerUpdate(apr, uint256(updates.aprUpdate));
            
            verifyLiq(msg.sender, _newCumLiqForClaims, _liqForClaimsProof);
            shield.setLiqForClaims(_newCumLiqForClaims);
        }
        // Only updates if it's a redeem request (which is the only call that's affected by reserved).
        if (lastUpdate <= updates.reservedUpdate && _redeem) {
            verifyReserved(msg.sender, _newPercentReserved, _percentReservedProof);
            shield.setPercentReserved(_newPercentReserved);
        }

        lastShieldUpdate[msg.sender] = uint32(block.timestamp);
    }

    /**
     * @notice Verify the signature approving the transaction.
     * @param _user User that is being minted to.
     * @param _amount Amount of underlying tokens being deposited.
     * @param _expiry Time (Unix timestamp) that this request expires.
     * @param _v The recovery byte of the signature.
     * @param _r Half of the ECDSA signature pair.
     * @param _s Half of the ECDSA signature pair.
     */
    function verifyCapacitySig(
        address _user,
        uint256 _amount,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "EASE_RCA_CONTROLLER_1.0",
                block.chainid,
                address(this),
                _user,
                msg.sender,
                _amount,
                nonces[_user]++,
                _expiry
            )
        );
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        address signatory = ecrecover(message, _v, _r, _s);

        require(signatory == capOracle, "Invalid capacity oracle signature.");
        require(block.timestamp <= _expiry, "Capacity permission has expired.");
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// view ////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Verify the current amount for liquidation.
     * @param _shield Address of the shield to verify.
     * @param _newCumLiqForClaims New cumulative amount liquidated.
     * @param _liqForClaimsProof Proof of the for sale amounts.
     */
    function verifyLiq(
        address _shield,
        uint256 _newCumLiqForClaims,
        bytes32[] memory _liqForClaimsProof
    ) public view {
        bytes32 leaf = keccak256(abi.encodePacked(_shield, _newCumLiqForClaims));
        require(MerkleProof.verify(_liqForClaimsProof, liqForClaimsRoot, leaf), "Incorrect liq proof.");
    }

    /**
     * @notice Verify price from Ease price oracle.
     * @param _shield Address of the shield to find price of.
     * @param _value Price of the underlying token (in Ether) for this shield.
     * @param _proof Merkle proof.
     */
    function verifyPrice(
        address _shield,
        uint256 _value,
        bytes32[] memory _proof
    ) public view {
        bytes32 leaf = keccak256(abi.encodePacked(_shield, _value));
        // This doesn't protect against oracle hacks, but does protect against some bugs.
        require(_value > 0, "Invalid price submitted.");
        require(MerkleProof.verify(_proof, priceRoot, leaf), "Incorrect price proof.");
    }

    /**
     * @notice Verify the percent reserved for a particular shield.
     * @param _shield Address of the shield/token to verify reserved.
     * @param _percentReserved Percent of shield that's reserved. 10% == 1000.
     * @param _proof The Merkle proof verifying the percent reserved.
     */
    function verifyReserved(
        address _shield,
        uint256 _percentReserved,
        bytes32[] memory _proof
    ) public view {
        bytes32 leaf = keccak256(abi.encodePacked(_shield, _percentReserved));
        require(MerkleProof.verify(_proof, reservedRoot, leaf), "Incorrect capacity proof.");
    }

    /**
     * @notice Makes it easier for frontend to get the balances on many shields.
     * @param _user User to find balances of.
     * @param _tokens The shields (also tokens) to find the RCA balances for.
     */
    function balanceOfs(address _user, address[] calldata _tokens) external view returns (uint256[] memory balances) {
        balances = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 balance = IERC20(_tokens[i]).balanceOf(_user);
            balances[i] = balance;
        }
    }

    /**
     * @notice Makes it easier for frontend to get the currently withdrawing requests for each shield.
     * @param _user User to find requests of.
     * @param _shields The shields to find the request data for.
     */
    function requestOfs(
        address _user, 
        address[] calldata _shields
    ) external view returns (IRcaShield.WithdrawRequest[] memory requests) {
        requests = new IRcaShield.WithdrawRequest[](_shields.length);

        for (uint256 i = 0; i < _shields.length; i++) {
            IRcaShield.WithdrawRequest memory request = IRcaShield(_shields[i]).withdrawRequests(_user);
            requests[i] = request;
        }
    }

    /**
     * @notice Used by frontend to craft signature for a requested transaction.
     * @param _user User that is being minted to.
     * @param _shield Address of the shield that tokens are being deposited into.
     * @param _amount Amount of underlying tokens to deposit.
     * @param _nonce User nonce (current nonce +1) that this transaction will be.
     * @param _expiry Time (Unix timestamp) that this request will expire.
     */
    function getMessageHash(
        address _user,
        address _shield,
        uint256 _amount,
        uint256 _nonce,
        uint256 _expiry
    ) external view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "EASE_RCA_CONTROLLER_1.0",
                    block.chainid,
                    address(this),
                    _user,
                    _shield,
                    _amount,
                    _nonce,
                    _expiry
                )
            );
    }

    function getAprUpdate() external view returns (uint32) {
        return systemUpdates.aprUpdate;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////// onlyGov //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Initialize a new shield.
     * @param _shield Address of the shield to initialize.
     */
    function initializeShield(address _shield) external onlyGov {
        IRcaShield(_shield).initialize(apr, discount, treasury, withdrawalDelay);

        shieldMapping[_shield] = true;
        activeShields[_shield] = true;
        lastShieldUpdate[_shield] = block.timestamp;

        emit ShieldCreated(
            _shield,
            address(IRcaShield(_shield).uToken()),
            IRcaShield(_shield).name(),
            IRcaShield(_shield).symbol(),
            block.timestamp
        );
    }

    /**
     * @notice Governance calls to set the new total amount for sale.
     * @param _newLiqRoot Merkle root for new total amounts for sale for each protocol (in token).
     * @param _newReservedRoot Reserved root setting all percent reserved back to 0.
     */
    function setLiqTotal(bytes32 _newLiqRoot, bytes32 _newReservedRoot) external onlyGov {
        liqForClaimsRoot = _newLiqRoot;
        systemUpdates.liqUpdate = uint32(block.timestamp);
        reservedRoot = _newReservedRoot;
        systemUpdates.reservedUpdate = uint32(block.timestamp);
    }

    /**
     * @notice Governance can reset withdrawal delay for amount of time it takes to withdraw from vaults.
     * Not a commonly used function, if at all really.
     * @param _newWithdrawalDelay New delay (in seconds) for withdrawals.
     */
    function setWithdrawalDelay(uint256 _newWithdrawalDelay) external onlyGov {
        require(_newWithdrawalDelay <= 86400 * 7, "Withdrawal delay may not be more than 7 days.");
        withdrawalDelay = _newWithdrawalDelay;
        systemUpdates.withdrawalDelayUpdate = uint32(block.timestamp);
    }

    /**
     * @notice Governance can change the amount of discount for purchasing tokens that are being liquidated.
     * @param _newDiscount New discount for purchase in tenths of a percent (1000 == 10%).
     */
    function setDiscount(uint256 _newDiscount) external onlyGov {
        require(_newDiscount <= 2500, "Discount may not be more than 25%.");
        discount = _newDiscount;
        systemUpdates.discountUpdate = uint32(block.timestamp);
    }

    /**
     * @notice Governance can set the fees taken per year from a vault. Starts at 0, can update at any time.
     * @param _newApr New fees per year for being in the RCA system (1000 == 10%).
     */
    function setApr(uint256 _newApr) external onlyGov {
        require(_newApr <= 2000, "APR may not be more than 20%.");
        apr = _newApr;
        systemUpdates.aprUpdate = uint32(block.timestamp);
    }

    /**
     * @notice Governance can set address of the new treasury contract that accepts funds.
     * @param _newTreasury New fees per year for being in the RCA system (1000 == 10%).
     */
    function setTreasury(address payable _newTreasury) external onlyGov {
        treasury = _newTreasury;
        systemUpdates.treasuryUpdate = uint32(block.timestamp);
    }

    /**
     * @notice Governance can cancel the shield support.
     * @param _shields An array of shield addresses that are being cancelled.
     */
    function cancelShield(address[] memory _shields) external onlyGov {
        for (uint256 i = 0; i < _shields.length; i++) {
            activeShields[_shields[i]] = false;
            emit ShieldCancelled(_shields[i]);
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// onlyGuardian ///////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Admin can set the percent paused. This pauses this percent of tokens from each shield
     * while the DAO analyzes losses. If a withdrawal occurs while reserved > 0,
     * the user will lose this percent of tokens.
     * @param _newReservedRoot Percent of shields to temporarily pause for each shield. 1000 == 10%.
     */
    function setPercentReserved(bytes32 _newReservedRoot) external onlyGuardian {
        reservedRoot = _newReservedRoot;
        systemUpdates.reservedUpdate = uint32(block.timestamp);
    }

    /**
     * @notice Admin can set which router is verified and which is not.
     * @param _routerAddress Address of a router.
     * @param _verified New verified status of the router.
     */
    function setRouterVerified(address _routerAddress, bool _verified) external onlyGuardian {
        isRouterVerified[_routerAddress] = _verified;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////// onlyPriceOracle //////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Set prices of all tokens with our oracle. This will likely be expanded so that price oracle is a
     * smart contract that accepts input from a few sources to increase decentralization.
     * @param _newPriceRoot Merkle root for new prices of each underlying token in
     * Ether (key is shield address or token for rewards).
     */
    function setPrices(bytes32 _newPriceRoot) external onlyPriceOracle {
        priceRoot = _newPriceRoot;
    }
}

/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;
import "../general/Governable.sol";

/**
 * @title Governable
 * @dev Pretty default ownable but with variable names changed to better convey owner.
 */
contract RcaGovernable is Governable {
    address public guardian;
    address public priceOracle;
    address public capOracle;

    event NewGuardian(address indexed oldGuardian, address indexed newGuardian);
    event NewPriceOracle(address indexed oldOracle, address indexed newOracle);
    event NewCapOracle(address indexed oldOracle, address indexed newOracle);

    /**
     * @dev The Ownable constructor sets the original s of the contract to the sender
     * account.
     */
    function initRcaGovernable(
        address _governor,
        address _guardian,
        address _capOracle,
        address _priceOracle
    ) internal {
        require(governor() == address(0), "already initialized");
        initializeGovernable(_governor);

        guardian = _guardian;
        capOracle = _capOracle;
        priceOracle = _priceOracle;

        emit NewGuardian(address(0), _guardian);
        emit NewCapOracle(address(0), _capOracle);
        emit NewPriceOracle(address(0), _priceOracle);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGuardian() {
        require(msg.sender == guardian, "msg.sender is not Guardian.");
        _;
    }

    modifier onlyPriceOracle() {
        require(msg.sender == priceOracle, "msg.sender is not price oracle.");
        _;
    }

    modifier onlyCapOracle() {
        require(msg.sender == capOracle, "msg.sender is not capacity oracle.");
        _;
    }

    /**
     * @notice Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newGuardian The address to transfer ownership to.
     */
    function setGuardian(address _newGuardian) public onlyGov {
        guardian = _newGuardian;
    }

    function setPriceOracle(address _newPriceOracle) public onlyGov {
        priceOracle = _newPriceOracle;
    }

    function setCapOracle(address _newCapOracle) public onlyGov {
        capOracle = _newCapOracle;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRcaShield {
    function setApr(uint256 apr) external;

    function setTreasury(address treasury) external;

    function setDiscount(uint256 discount) external;

    function setLiqForClaims(uint256 addForSale) external;

    function setPercentReserved(uint256 percentPaused) external;

    function setWithdrawalDelay(uint256 withdrawalDelay) external;

    function initialize(
        uint256 apr,
        uint256 discount,
        address treasury,
        uint256 withdrawalDelay
    ) external;

    function name() external returns (string calldata);

    function symbol() external returns (string calldata);

    function uToken() external returns (IERC20);

    function controllerUpdate(uint256 apr, uint256 aprUpdate) external;

    struct WithdrawRequest {
        uint112 uAmount;
        uint112 rcaAmount;
        uint32 endTime;
    }

    function withdrawRequests(address user) external view returns (WithdrawRequest memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.11;

/**
 * @title Governable
 * @dev Pretty default ownable but with variable names changed to better convey owner.
 */
contract Governable {
    address payable private _governor;
    address payable private _pendingGovernor;

    event OwnershipTransferred(address indexed previousGovernor, address indexed newGovernor);
    event PendingOwnershipTransfer(address indexed from, address indexed to);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeGovernable(address _newGovernor) internal {
        require(_governor == address(0), "already initialized");
        _governor = payable(_newGovernor);
        emit OwnershipTransferred(address(0), _newGovernor);
    }

    /**
     * @return the address of the owner.
     */
    function governor() public view returns (address payable) {
        return _governor;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGov() {
        require(isGov(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isGov() public view returns (bool) {
        return msg.sender == _governor;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function transferOwnership(address payable newGovernor) public onlyGov {
        _pendingGovernor = newGovernor;
        emit PendingOwnershipTransfer(_governor, newGovernor);
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingGovernor, "Only pending governor can call this function");
        _transferOwnership(_pendingGovernor);
        _pendingGovernor = payable(address(0));
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function _transferOwnership(address payable newGovernor) internal {
        require(newGovernor != address(0));
        emit OwnershipTransferred(_governor, newGovernor);
        _governor = newGovernor;
    }

    uint256[50] private __gap;
}