// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/BAPGenesisInterface.sol";
import "./Interfaces/BAPMethaneInterface.sol";
import "./Interfaces/BAPUtilitiesInterface.sol";
import "./Interfaces/BAPTeenBullsInterface.sol";
import "./Interfaces/BAPOrchestratorInterface.sol";
import "./IERC721Receiver.sol";

/**
 * A number of codes are defined as error messages.
 * Codes are resembling HTTP statuses. This is the structure
 * CODE:SHORT
 * Where CODE is a number and SHORT is a short word or prase
 * describing the condition
 * CODES:
 * 100  contract status: open/closed, depleted. In general for any flag
 *     causing the mint to not to happen.
 * 200  parameters validation errors, like zero address or wrong values
 * 300  User payment amount errors like not enough funds.
 * 400  Contract amount/availability errors like not enough tokens or empty vault.
 * 500  permission errors, like not whitelisted, wrong address, not the owner.
 */

contract BAPOrchestrator is Ownable, IERC721Receiver {
    string public project = "Bulls & Apes Project";

    // ADDRESSES
    address public treasuryWallet;
    address public secret;

    // VARIABLES
    // uint256 public timeCounter = 1 days; // MAINNET
    uint256 public timeCounter = 1 hours; // TESTNET
    uint256 public grazingPeriodTime = 31 days;
    uint256 public powerCooldown = 15 days;
    // uint256 private godBullIndex = 10010; // we really need this??
    uint256 public lastTokenReceived; // make private on MAINNET

    bool private refundFlag = false;
    bool private claimFlag = false;
    bool private isReviving = false;

    mapping(address => uint256) public userLastClaim;
    mapping(uint256 => uint256) public claimedMeth;
    mapping(uint256 => uint256) public breedingsLeft;
    mapping(uint256 => uint256) public godsMintingDate;
    mapping(uint256 => uint256) public lastChestOpen;
    mapping(uint256 => uint256) public teenLastClaim;
    mapping(uint256 => bool) public isTokenUpdated;
    // mapping(bytes => bool) public usedSignature;

    // CONTRACTS INTERFACES
    BAPGenesisInterface public bapGenesis;
    BAPMethaneInterface public bapMeth;
    BAPUtilitiesInterface public bapUtilities;
    BAPTeenBullsInterface public bapTeenBulls;
    BAPOrchestratorInterface public bapOrchestratorV1;
    BAPOrchestratorInterface public bapOrchestratorV2;

    event CHEST_OPENED(uint256 godId, uint256 num, uint256 timestamp);
    event METH_CLAIMED(address user, uint256 amount, uint256 timestamp);

    constructor(
        address _bapGenesis,
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls,
        address _orchestratorV1,
        address _orchestratorV2
    ) {
        bapGenesis = BAPGenesisInterface(_bapGenesis);
        bapMeth = BAPMethaneInterface(_bapMethane);
        bapUtilities = BAPUtilitiesInterface(_bapUtilities);
        bapTeenBulls = BAPTeenBullsInterface(_bapTeenBulls);
        bapOrchestratorV1 = BAPOrchestratorInterface(_orchestratorV1);
        bapOrchestratorV2 = BAPOrchestratorInterface(_orchestratorV2);
    }

    modifier noZeroAddress(address _address) {
        require(_address != address(0), "200:ZERO_ADDRESS");
        _;
    }

    modifier checkUpdate(uint256 tokenId) {
        _updateToken(tokenId);
        _;
    }

    // TESTNET FUNCTIONS - DELETE FOR MAINNET
    function generateTeenBull(uint256 amount) external {
        for (uint256 i; i < amount; i++) {
            bapTeenBulls.generateTeenBull();
        }
    }

    function generateGodBull(uint256 amount) external {
        for (uint256 i; i < amount; i++) {
            godsMintingDate[bapGenesis.minted() + 1] = block.timestamp;
            isTokenUpdated[bapGenesis.minted() + 1] = true;
            bapGenesis.generateGodBull();
        }
    }

    function getMeth(uint256 amount) external {
        bapMeth.claim(msg.sender, amount);
    }

    // END TESTNET FUNCTIONS - DELETE FOR MAINNET

    function claimMeth(
        // check if signature is really needed.
        uint256[] memory bulls,
        uint256[] memory gods,
        uint256[] memory teens
    ) external {
        // can we avoid using reentrant ? it's really needed?
        require(
            bapGenesis.genesisTimestamp() + grazingPeriodTime <=
                block.timestamp ||
                claimFlag,
            "Grazing Period is not Finished"
        );

        uint256 claimableMeth;

        for (uint256 i; i < gods.length; i++) {
            claimableMeth += _claimMeth(gods[i], false);
        }
        for (uint256 i; i < bulls.length; i++) {
            claimableMeth += _claimMeth(bulls[i], false);
        }
        for (uint256 i; i < teens.length; i++) {
            claimableMeth += _claimMeth(teens[i], true);
        }

        bapMeth.claim(_msgSender(), claimableMeth);
    }

    function generateTeenBull() external {
        // check if signature is really needed. // can we avoid using reentrant ? it's really needed?
        bapMeth.pay(600, 300);
        bapUtilities.burn(1, 1);
        bapTeenBulls.generateTeenBull();
    }

    function generateGodBull(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2,
        uint256 bull3,
        uint256 bull4
    ) external {
        // can we avoid using reentrant ? it's really needed?
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, bull1, bull2, bull3, bull4)),
                signature
            ),
            "Signature is invalid"
        );
        bapMeth.pay(4800, 2400);
        bapUtilities.burn(2, 1);
        _burnTeen(bull1);
        _burnTeen(bull2);
        _burnTeen(bull3);
        _burnTeen(bull4);
        godsMintingDate[bapGenesis.minted() + 1] = block.timestamp; // TEST THIS APPROACH !!!!
        isTokenUpdated[bapGenesis.minted() + 1] = true;
        bapGenesis.generateGodBull();
    }

    function buyIncubator(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2
    ) external {
        // can we avoid using reentrant ? it's really needed?
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, bull1, bull2)),
                signature
            ),
            "Signature is invalid"
        );
        bapMeth.pay(600, 300);
        _breedToken(bull1);
        _breedToken(bull2);
        bapUtilities.purchaseIncubator();
    }

    // check if signature is really needed.
    function buyMergeOrb(uint256 teen) external {
        // can we avoid using reentrant ? it's really needed?
        bapMeth.pay(2400, 1200);
        _burnTeen(teen);
        bapUtilities.purchaseMergerOrb();
    }

    function refund(uint256 tokenId) external noZeroAddress(treasuryWallet) {
        // can we avoid using reentrant ? it's really needed? // TEST NO REENTRANCY IS POSSIBLE !!!
        require(
            _refundPeriodAllowed() || refundFlag,
            "The Refund is not allowed"
        );
        require(
            bapGenesis.breedings(tokenId) == bapGenesis.maxBreedings(),
            "The bull breed"
        );
        require(_claimedMeth(tokenId) == 0, "Tokens claimed for this Bull");

        bapGenesis.refund(msg.sender, tokenId);
        bapGenesis.safeTransferFrom(msg.sender, treasuryWallet, tokenId);
    }

    // NEW FUNCTIONS

    // GUILD: 0 N - 1 S - 2 E - 3 W
    function openChest(
        uint256 godId,
        uint256 guild,
        uint256 seed,
        bool hasPower,
        bytes memory signature
    ) external checkUpdate(godId) {
        require(seed > block.timestamp, "seed is no longer valid");
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, godId, guild, seed, hasPower)),
                signature
            ),
            "Signature is invalid"
        );
        require(bapGenesis.ownerOf(godId) == msg.sender, "Only the owner");
        require(godBulls(godId), "Not a god bull");
        // require(!usedSignature[signature], "Signature already used"); // check if we don't need this anymore - we have seed deadline
        // usedSignature[signature] = true;

        if (
            !hasPower || lastChestOpen[godId] + powerCooldown > block.timestamp
        ) {
            // check which approach is better
            require(
                lastChestOpen[godId] + 20 minutes > block.timestamp,
                "re open time elapsed"
            );

            bapMeth.pay(1200, 1200);
            // ensure to don't re-open again
            lastChestOpen[godId] = block.timestamp - 21 minutes;
        } else {
            // require(
            //     lastChestOpen[godId] + powerCooldown < block.timestamp,
            //     "god is on cooldown period"
            // );
            bapMeth.pay(600, 600);
            lastChestOpen[godId] = block.timestamp;
        }

        uint256 num = random(seed) % 100; // NUM BETWEEN 0 - 99

        if (num < 10) {
            bapUtilities.airdrop(msg.sender, 1, (20 + guild)); // UTILITIE #20 - 23 METH MAKER - 10% (num between 0 - 9)
        } else if (num < 40) {
            bapUtilities.airdrop(msg.sender, 1, (30 + guild)); // UTILITIE #30 - 33 RESURRECTION - 30% (num between 10 - 39)
        } else {
            bapUtilities.airdrop(msg.sender, 1, (40 + guild)); // UTILITIE #40 - 43 BREED REPLENISH - 60% (num between 40 - 099)
        }

        emit CHEST_OPENED(godId, num, block.timestamp);
    }

    function useItem(
        uint256 item,
        uint256 tokenId,
        uint256 godId,
        bytes memory signature
    ) external {
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, item, tokenId)),
                signature
            ),
            "Signature is invalid"
        );

        bapUtilities.burn(item, 1); // #30 - 33 RESURRECTION, #40 - 43 BREED REPLENISH

        if (item >= 30 && item < 35) {
            require(
                teenLastClaim[tokenId] == 0,
                "this teen has already resurrect"
            );
            require(godBulls(godId), "You need to use a good");
            require(bapGenesis.ownerOf(godId) == msg.sender, "Only the owner");

            _burnTeen(tokenId);

            isReviving = true;

            bapTeenBulls.airdrop(address(this), 1);

            teenLastClaim[lastTokenReceived] = block.timestamp;

            isReviving = false;

            bapTeenBulls.safeTransferFrom(
                address(this),
                msg.sender,
                lastTokenReceived
            );

            lastTokenReceived = 0;
        } else if (item >= 40 && item < 45) {
            require(
                bapGenesis.ownerOf(tokenId) == msg.sender,
                "Only the owner"
            );
            require(
                !godBulls(tokenId),
                "God bulls cannot claim extra breeding"
            );

            uint256 currentBreeds = bapGenesis.breedings(tokenId);

            breedingsLeft[tokenId] = 3 - currentBreeds;
        } else {
            require(false, "Wrong item id");
        }
    }

    function claimTeenMeth(
        uint256 amount,
        uint256 seed,
        bytes memory signature
    ) external {
        require(seed > block.timestamp, "seed is no longer valid");
        require(
            userLastClaim[msg.sender] + 1 days < block.timestamp,
            "can claim only once a day"
        );
        require(
            _verifyHashSignature(
                keccak256(abi.encode(amount, seed, msg.sender)),
                signature
            ),
            "Signature is invalid"
        );
        // require(!usedSignature[signature], "Signature already used"); // check if we don't need this anymore - we have seed deadline
        // usedSignature[signature] = true;

        userLastClaim[msg.sender] = block.timestamp;

        bapMeth.claim(msg.sender, amount);

        emit METH_CLAIMED(msg.sender, amount, block.timestamp);
    }

    // INTERNAL FUNCTIONS

    function _claimMeth(uint256 tokenId, bool isTeen)
        internal
        checkUpdate(tokenId)
        returns (uint256 amount)
    {
        if (!isTeen) {
            require(
                bapGenesis.ownerOf(tokenId) == _msgSender(),
                "Sender is not the owner"
            );

            if (godBulls(tokenId)) {
                amount = getClaimableMeth(tokenId, 1);
            } else {
                amount = getClaimableMeth(tokenId, 0);
            }

            claimedMeth[tokenId] += amount;
        } else {
            require(
                bapTeenBulls.ownerOf(tokenId) == msg.sender,
                "Sender is not the owner"
            );
            require(teenLastClaim[tokenId] != 0, "this teen is not resurrect");

            amount = getClaimableMeth(tokenId, 2);
            teenLastClaim[tokenId] = block.timestamp;
        }
    }

    function _breedToken(uint256 tokenId) internal {
        require(
            bapGenesis.ownerOf(tokenId) == msg.sender,
            "Only the owner can breed"
        );

        uint256 currentBreeds = bapGenesis.breedings(tokenId);

        if (currentBreeds != 0) {
            bapGenesis.updateBullBreedings(tokenId);
        } else {
            require(breedingsLeft[tokenId] != 0, "No more breadings left");
            breedingsLeft[tokenId]--;
        }
    }

    function _burnTeen(uint256 tokenId) internal {
        require(
            bapTeenBulls.ownerOf(tokenId) == msg.sender,
            "Only the owner can burn"
        );

        bapTeenBulls.burnTeenBull(tokenId);
    }

    function _updateToken(uint256 tokenId) internal {
        if (isTokenUpdated[tokenId]) {
            return;
        }

        claimedMeth[tokenId] =
            bapOrchestratorV1.claimedMeth(tokenId) +
            bapOrchestratorV2.claimedMeth(tokenId);
        godsMintingDate[tokenId] = bapOrchestratorV2.godsMintingDate(tokenId);

        isTokenUpdated[tokenId] = true;
    }

    function _godMintingDate(uint256 tokenId) public view returns (uint256) {
        if (isTokenUpdated[tokenId]) {
            return godsMintingDate[tokenId];
        }

        return bapOrchestratorV2.godsMintingDate(tokenId);
    }

    function _claimedMeth(uint256 tokenId) public view returns (uint256) {
        if (isTokenUpdated[tokenId]) {
            return claimedMeth[tokenId];
        }

        return
            bapOrchestratorV1.claimedMeth(tokenId) +
            bapOrchestratorV2.claimedMeth(tokenId);
    }

    function breedings(uint256 tokenId) public view returns (uint256) {
        uint256 currentBreeds = bapGenesis.breedings(tokenId);

        return currentBreeds + breedingsLeft[tokenId];
    }

    function godBulls(uint256 tokenId) public view returns (bool) {
        if (isTokenUpdated[tokenId]) {
            godsMintingDate[tokenId] != 0;
        }

        return _godMintingDate(tokenId) != 0;
    }

    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.timestamp,
                        gasleft(),
                        tx.origin
                    )
                )
            );
    }

    // VIEW FUNCTIONS
    // _type 0 - Bull, 1 - God, 2 - Teen
    function getClaimableMeth(uint256 tokenId, uint256 _type)
        public
        view
        returns (uint256)
    {
        uint256 startTime;

        if (_type == 0) {
            startTime = bapGenesis.mintingDatetime(tokenId);
        } else if (_type == 1) {
            startTime = _godMintingDate(tokenId);
        } else if (_type == 2) {
            startTime = teenLastClaim[tokenId];
        }

        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);
        uint256 claimed = _type == 2 ? 0 : _claimedMeth(tokenId);

        return (_dailyRewards(_type) * timeFromCreation) - claimed;
    }

    // _type 0 - Bull, 1 - God, 2 - Teen
    function _dailyRewards(uint256 _type) internal pure returns (uint256) {
        if (_type == 0) {
            return 10;
        } else if (_type == 1) {
            return 20;
        } else {
            return 5;
        }
    }

    function _refundPeriodAllowed() internal view returns (bool) {
        return
            block.timestamp >= bapGenesis.genesisTimestamp() + 31 days &&
            block.timestamp <= bapGenesis.genesisTimestamp() + 180 days;
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(
            msg.sender == address(bapTeenBulls),
            "Only receive from BAP Teens"
        );
        require(isReviving, "Only accept transfers while reviving");
        lastTokenReceived = tokenId;
        return this.onERC721Received.selector;
    }

    // OWNER FUNCTIONS

    function forceUpdate(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            _updateToken(tokenIds[i]);
        }
    }

    function transferOwnership(address _contract, address _newOwner)
        external
        onlyOwner
        noZeroAddress(_newOwner)
    {
        Ownable(_contract).transferOwnership(_newOwner);
    }

    function utilitiesAirdrop(
        address _to,
        uint256 amount,
        uint256 utility
    ) external onlyOwner noZeroAddress(_to) {
        bapUtilities.airdrop(_to, amount, utility);
    }

    function teenAirdrop(address _to, uint256 amount)
        external
        onlyOwner
        noZeroAddress(_to)
    {
        bapTeenBulls.airdrop(_to, amount);
    }

    function setGenesisContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapGenesis = BAPGenesisInterface(_newAddress);
    }

    function setMethaneContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapMeth = BAPMethaneInterface(_newAddress);
    }

    function setUtilitiesContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapUtilities = BAPUtilitiesInterface(_newAddress);
    }

    function setTeenBullsContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapTeenBulls = BAPTeenBullsInterface(_newAddress);
    }

    function setTreasuryWallet(address _newTreasuryWallet)
        external
        onlyOwner
        noZeroAddress(_newTreasuryWallet)
    {
        treasuryWallet = _newTreasuryWallet;
    }

    function setPrevOrchestrators(
        address _orchestratorV1,
        address _orchestratorV2
    )
        external
        onlyOwner
        noZeroAddress(_orchestratorV1)
        noZeroAddress(_orchestratorV2)
    {
        bapOrchestratorV1 = BAPOrchestratorInterface(_orchestratorV1);
        bapOrchestratorV2 = BAPOrchestratorInterface(_orchestratorV2);
    }

    function setWhitelistedAddress(address _secret)
        external
        onlyOwner
        noZeroAddress(_secret)
    {
        secret = _secret;
    }

    function setGrazingPeriodTime(uint256 _grazingPeriod) external onlyOwner {
        grazingPeriodTime = _grazingPeriod;
    }

    function setTimeCounter(uint256 _timeCounter) external onlyOwner {
        timeCounter = _timeCounter;
    }

    function setPowerCooldown(uint256 _powerCooldown) external onlyOwner {
        powerCooldown = _powerCooldown;
    }

    function setRefundFlag(bool _refundFlag) external onlyOwner {
        refundFlag = _refundFlag;
    }

    function setClaimFlag(bool _claimFlag) external onlyOwner {
        claimFlag = _claimFlag;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPUtilitiesInterface {
    function purchaseIncubator() external;

    function purchaseMergerOrb() external;

    function transferOwnership(address) external;

    function balanceOf(address, uint256) external returns (uint256);

    function burn(uint256, uint256) external;

    function airdrop(
        address,
        uint256,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPTeenBullsInterface {
    function generateTeenBull() external;

    function generateMergerOrb() external;

    function ownerOf(uint256) external view returns (address);

    function burnTeenBull(uint256) external;

    function airdrop(address, uint256) external;

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPOrchestratorInterface {
    function mintingRefunded(uint256) external returns (bool);

    function claimedMeth(uint256) external view returns (uint256);

    function godsMintingDate(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPMethaneInterface {
  function name() external view returns (string memory);
  function maxSupply() external view returns (uint256);
  function claims(address) external view returns (uint256);
  function claim(address, uint256) external;
  function pay(uint256,uint256) external;
  function treasuryWallet() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface BAPGenesisInterface {
  function mintingDatetime(uint256) external view returns (uint256);
  function tokenExist(uint256) external view returns (bool);
  function ownerOf(uint256) external view returns (address);
  function dailyRewards(bool) external view returns (uint256);
  function initialMintingTimestamp() external view returns (uint256);
  function originalMintingPrice(uint256) external view returns (uint256);
  function breedings(uint256) external view returns (uint256);
  function maxBreedings() external view returns (uint256);
  function breedBulls(uint256,uint256) external;
  function _orchestrator() external view returns (address);
  function approve(address, uint256) external;
  function refund(address, uint256) external payable;
  function safeTransferFrom(address,address,uint256) external;
  function refundPeriodAllowed(uint256) external view returns(bool);
  function notAvailableForRefund(uint256) external returns(bool);
  function generateGodBull() external;
  function genesisTimestamp() external view returns(uint256);
  function setGrazingPeriodTime(uint256) external;
  function setTimeCounter(uint256) external; 
  function secret() external view returns(address);
  function minted() external view returns(uint256);
  function updateBullBreedings(uint256) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0

pragma solidity ^0.8.4;

/**
 * @dev ERC721 token receiver interface.
 */
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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