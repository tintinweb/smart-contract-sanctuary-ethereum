/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// contract ERC721Receiver {
//   bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

//   function onERC721Received(
//     address _operator,
//     address _from,
//     uint256 _tokenId,
//     bytes calldata _data
//   )
//     public virtual
//     returns(bytes4);
// }

interface IHornets is IERC721 {
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
}

interface IArmory is IERC721 {
    function burn(uint256 _id) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IResource is IERC20 {
    function accountMint(address account, uint256 amount) external;

    function accountBurn(address account, uint256 amount) external;
}

contract HiveManager is Ownable, IERC721Receiver {
    using SafeMath for uint256;

    struct HornetInfo {
        uint256 id;
        uint256 status; // 0 -> unstaked, 1 -> working, 2 -> guarding
        address owner;
        uint256 hiveId;
        uint256 lastProcessingDay;
        uint256 multiplier;
        uint256 stakedDay;
    }

    struct HiveInfo {
        uint256[] hornets;
        bool isRunning;
        uint256[] nectarFarms;
        address[] nectarFarmOwners;
        uint256[] toxicForceFields;
        address[] toxicForceFieldOwners;
        uint256 startTime;
        uint256 yieldVenom;
        uint256 health;
    }

    struct HiveDayInfo {
        uint256 signedWorkers;
        uint256 signedGuards;
        uint256 yieldVenom;
        uint256 defense;
    }

    struct UserInfo {
        uint256[] hornets;
        uint256 damage;
    }

    struct InvaderInfo {
        uint256 status; // 0 - living, 1 -> injured, 2 -> severely injured
        uint256 lastProcessingTime;
    }

    struct AttackInfo {
        uint256[] timestamps;
        uint256[] statuses; // 0 -> critical, 1 -> basic, 2 -> nothing, 3 -> severely injured, 4 -> injured, 5 -> retreat
        uint256[] damages;
        uint256 damage;
    }

    mapping (uint256 => HornetInfo) public hornetInfo;
    mapping (uint256 => HiveInfo) public hiveInfo;
    mapping (uint256 => mapping(uint256 => HiveDayInfo)) public hiveDayInfo;
    mapping (uint256 => mapping(address => UserInfo)) public userInfo;
    mapping (uint256 => InvaderInfo) public invaderInfo;
    mapping (uint256 => mapping(uint256 => AttackInfo)) public attackInfo;

    IResource public Venom;
    IHornets public HornetsNFT;
    IERC721 public InvadersNFT;
    IArmory public NectarFarmsNFT;
    IArmory public ToxicForceFieldsNFT;
    IArmory public ClawReinforcementsNFT;
    // IArmory public RageSerumNFT;
    IArmory public AntiVenomPlatingsNFT;

    uint256 public staticDefensePerGuard = 5;
    uint256 public staticHealth = 1000000;
    uint256 public seasonDays = 30;
    uint256 public nectarFarmRate = 20;
    uint256 public nectarFarmMaxRate = 200;

    constructor(
        address _venom,
        address _hornetsNFT,
        address _invadersNFT,
        address _nectarFarmsNFT,
        address _toxicForceFieldsNFT,
        address _clawReinforcementsNFT,
        // address _rageSerumNFT,
        address _antiVenomPlatingsNFT
    ) {
        Venom = IResource(_venom);
        HornetsNFT = IHornets(_hornetsNFT);
        InvadersNFT = IERC721(_invadersNFT);
        NectarFarmsNFT = IArmory(_nectarFarmsNFT);
        ToxicForceFieldsNFT = IArmory(_toxicForceFieldsNFT);
        ClawReinforcementsNFT = IArmory(_clawReinforcementsNFT);
        // RageSerumNFT = IArmory(_rageSerumNFT);
        AntiVenomPlatingsNFT = IArmory(_antiVenomPlatingsNFT);
    }

    function InitializeHiveByAdmin(uint256 _hid) public onlyOwner {
        FinishHive(_hid);
        HiveInfo storage hive = hiveInfo[_hid];
        hive.isRunning = true;
        hive.startTime = block.timestamp;
        hive.health = staticHealth;
    }

    function FinishHive(uint256 _hid) private {
        HiveInfo storage hive = hiveInfo[_hid];

        if (hive.health == 0) {
            Venom.accountMint(msg.sender, hive.yieldVenom.mul(20).div(100));
            for (uint256 index = 0; index < InvadersNFT.totalSupply(); index++) {
                if (attackInfo[_hid][index].damage != 0) {
                    uint256 amount = hive.yieldVenom.mul(80).div(100).mul(attackInfo[_hid][index].damage).div(staticHealth);
                    Venom.accountMint(InvadersNFT.ownerOf(index), amount);
                }
            }
        } else {
            for (uint256 index = 0; index < hive.hornets.length; index++) {
                HornetInfo storage hornet = hornetInfo[hive.hornets[index]];
                uint256 amount = getYieldFromHornet(_hid, hive.hornets[index]);
                Venom.accountMint(hornet.owner, amount);
            }
        }

        for (uint256 index = 0; index < hive.nectarFarms.length; index++) {
            NectarFarmsNFT.safeTransferFrom(address(this), hive.nectarFarmOwners[index], hive.nectarFarms[index]);
        }

        for (uint256 index = 0; index < hive.toxicForceFields.length; index++) {
            ToxicForceFieldsNFT.safeTransferFrom(address(this), hive.toxicForceFieldOwners[index], hive.toxicForceFields[index]);
        }

        for (uint256 index = 0; index < hive.hornets.length; index++) {
            uint256 nftId = hive.hornets[index];
            HornetsNFT.safeTransferFrom(address(this), hornetInfo[nftId].owner, nftId);
            delete userInfo[_hid][hornetInfo[nftId].owner];
            delete hornetInfo[nftId];
        }

        for (uint256 index = 0; index < 31; index++) {
            delete hiveDayInfo[_hid][index];
        }

        for (uint256 index = 0; index < InvadersNFT.totalSupply(); index++) {
            delete attackInfo[_hid][index];
        }

        delete hiveInfo[_hid];
    }

    function CalculateDayOfHive(uint256 _hid) public view returns (uint256) {
        HiveInfo storage hive = hiveInfo[_hid];
        return (block.timestamp - hive.startTime) / 86400;
    }

    function StakeHive(uint256 _hid, uint256[] memory _hornets, bool _isWorker) public {
        HiveInfo storage hive = hiveInfo[_hid];

        require(hive.isRunning, "HiveManager: The Hive is not started yet.");
        require(hive.hornets.length + _hornets.length < 1001, "HiveManager: Hornets in hive can't exceed 1000.");
        require(hive.health > 0, "HiveManager: The Season is ended.");

        uint256 today = CalculateDayOfHive(_hid);

        require(today < seasonDays, "HiveManager: The season is ended.");

        HiveDayInfo storage hiveDay = hiveDayInfo[_hid][today];

        if (_isWorker) {
            require(hiveDay.signedWorkers + _hornets.length <= 900, "HiveManager: Workers in hive can't exceed 900.");
            hiveDay.signedWorkers += _hornets.length;
        } else {
            require(hiveDay.signedGuards + _hornets.length <= 100, "HiveManager: Guards in hive can't exceed 900.");
            hiveDay.signedGuards += _hornets.length;
        }

        UserInfo storage user = userInfo[_hid][msg.sender];

        for (uint256 index = 0; index < _hornets.length; index++) {
            require(HornetsNFT.ownerOf(_hornets[index]) == msg.sender, "HiveManager: You are not owner of some items.");

            HornetInfo storage hornet = hornetInfo[_hornets[index]];
            hornet.id = _hornets[index];
            hornet.status = _isWorker? 1 : 2;
            hornet.owner = msg.sender;
            hornet.hiveId = _hid;
            hornet.lastProcessingDay = today;
            hornet.multiplier = 100;
            hornet.stakedDay = today;

            hive.hornets.push(hornet.id);
            user.hornets.push(hornet.id);

            if (_isWorker) {
                hive.yieldVenom += 10**18;
                hiveDay.signedWorkers = hornet.status == 1 ? hiveDay.signedWorkers : hiveDay.signedWorkers + 1;
                hiveDay.signedGuards = hornet.status == 2 ? hiveDay.signedGuards - 1 : hiveDay.signedGuards;
            } else {
                hiveDay.defense += staticDefensePerGuard;
                hiveDay.signedWorkers = hornet.status == 1 ? hiveDay.signedWorkers - 1 : hiveDay.signedWorkers;
                hiveDay.signedGuards = hornet.status == 2 ? hiveDay.signedGuards : hiveDay.signedGuards + 1;
            }

            HornetsNFT.safeTransferFrom(msg.sender, address(this), _hornets[index]);
        }
    }

    function ContributeNF(uint256 _hid, uint256[] memory _items) public {
        HiveInfo storage hive = hiveInfo[_hid];
        require(hive.health > 0, "HiveManager: The Season is ended.");
        require(hive.nectarFarms.length + _items.length <= 5, "HiveManager: NF can't exceed 5.");

        uint256 today = CalculateDayOfHive(_hid);
        require(today < seasonDays, "HiveManager: The season is ended.");

        for (uint256 index = 0; index < _items.length; index++) {
            require(NectarFarmsNFT.ownerOf(_items[index]) == msg.sender, "HiveManager: You are not owner of some items.");
            hive.nectarFarms.push(_items[index]);
            hive.nectarFarmOwners.push(msg.sender);
            NectarFarmsNFT.safeTransferFrom(msg.sender, address(this), _items[index]);
        }
    }

    function ContributeTF(uint256 _hid, uint256[] memory _items) public {
        HiveInfo storage hive = hiveInfo[_hid];
        require(hive.health > 0, "HiveManager: The Season is ended.");
        require(hive.toxicForceFields.length + _items.length <= 20, "HiveManager: TF can't exceed 20.");

        uint256 today = CalculateDayOfHive(_hid);
        require(today < seasonDays, "HiveManager: The season is ended.");

        for (uint256 index = 0; index < _items.length; index++) {
            require(ToxicForceFieldsNFT.ownerOf(_items[index]) == msg.sender, "HiveManager: You are not owner of some items.");
            hive.toxicForceFields.push(_items[index]);
            hive.toxicForceFieldOwners.push(msg.sender);
            ToxicForceFieldsNFT.safeTransferFrom(msg.sender, address(this), _items[index]);
        }
    }

    function ActionHive(uint256 _hid, uint256 _hornetId, bool _isHarvest) public {
        HiveInfo storage hive = hiveInfo[_hid];

        require(hive.health > 0, "HiveManager: The Season is ended.");

        uint256 today = CalculateDayOfHive(_hid);

        require(today > 0, "HiveManager: Can't Harvest or Protect on first day.");
        require(today < seasonDays, "HiveManager: The season is ended.");

        HiveDayInfo storage hiveDay = hiveDayInfo[_hid][today];
        HornetInfo storage hornet = hornetInfo[_hornetId];

        require(hornet.status != 0, "HiveManager: unstaked");
        require(hornet.owner == msg.sender, "HiveManager: not owner");
        require(hornet.hiveId == _hid, "HiveManager: another hive");
        require(hornet.lastProcessingDay < today, "HiveManager: can't harvest or protect in a day.");

        uint256 passedDays = today - hornet.lastProcessingDay;

        if (passedDays <= 1) {
            hornet.multiplier = hornet.multiplier > nectarFarmMaxRate - nectarFarmRate? nectarFarmMaxRate : hornet.multiplier + nectarFarmRate;
        } else {
            hornet.multiplier = hornet.multiplier > nectarFarmRate? hornet.multiplier - nectarFarmRate : 0;
        }

        Venom.accountMint(msg.sender, hornet.multiplier.mul(10**16));
        if (_isHarvest) {
            hiveDay.yieldVenom += (100 + hive.nectarFarms.length * nectarFarmRate) * 10**16;
            hive.yieldVenom += (100 + hive.nectarFarms.length * nectarFarmRate) * 10**16;
            hiveDay.signedWorkers = hornet.status == 1 ? hiveDay.signedWorkers : hiveDay.signedWorkers + 1;
            hiveDay.signedGuards = hornet.status == 2 ? hiveDay.signedGuards - 1 : hiveDay.signedGuards;
        } else {
            hiveDay.defense += staticDefensePerGuard;
            hiveDay.signedWorkers = hornet.status == 1 ? hiveDay.signedWorkers - 1 : hiveDay.signedWorkers;
            hiveDay.signedGuards = hornet.status == 2 ? hiveDay.signedGuards : hiveDay.signedGuards + 1;
        }
        hornet.status = _isHarvest? 1 : 2;
        hornet.lastProcessingDay = today;
    }

    function AttackHive(uint256 _hid, uint256 _invader,  uint256[] memory _AVP, uint256[] memory _CRs) public {

        require(InvadersNFT.ownerOf(_invader) == msg.sender, "HiveManager: You are not owner of this Invader.");
        require(_AVP.length <= 1, "HiveManager: AVP number is less than 1.");
        // require(_RS.length <= 1, "HiveManager: RS number is less than 1.");
        if (_AVP.length == 1) {
            require(AntiVenomPlatingsNFT.ownerOf(_AVP[0]) == msg.sender, "HiveManager: You are not owner of this AVP.");
            AntiVenomPlatingsNFT.burn(_AVP[0]);
        }
        // if (_RS.length == 1) {
        //     require(RageSerumNFT.ownerOf(_RS[0]) == msg.sender, "HiveManager: You are not owner of this RS.");
        //     RageSerumNFT.burn(_RS[0]);
        // }
        require(_CRs.length <= 4, "HiveManager: over 4 Claw Reinforcements");
        for (uint256 index = 0; index < _CRs.length; index++) {
            require(ClawReinforcementsNFT.ownerOf(_CRs[index]) == msg.sender, "HiveManager: You are not owner of this CR.");
        }

        HiveInfo storage hive = hiveInfo[_hid];

        require(hive.health > 0, "HiveManager: The Season is ended.");

        uint256 today = CalculateDayOfHive(_hid);

        require(today > 0, "HiveManager: Can't Attack on first day.");
        require(today < seasonDays, "HiveManager: The season is ended.");

        HiveDayInfo storage hiveDay = hiveDayInfo[_hid][today-1];

        InvaderInfo storage invader = invaderInfo[_invader];

        uint256 timeDelay = 0;

        if (invader.status == 0) {
            timeDelay = 86400;
        }
        if (invader.status == 1) {
            timeDelay = 86400 * 5;
        }
        if (invader.status == 2) {
            timeDelay = 86400 * 8;
        }

        require(block.timestamp - invader.lastProcessingTime > timeDelay, "HiveManager: The Invader must spend correct period.");

        AttackInfo storage attack = attackInfo[_hid][_invader];

        uint256 attackRate = 50 + _CRs.length * 5 - hive.toxicForceFields.length;

        uint256 random = getRandomNumber(10000);

        if (random < attackRate * 100) {
            SuccessfulAttack(hive, hiveDay, attack, random, attackRate);
        } else {
            bool hasAVP = _AVP.length == 1;
            FailedAttack(invader, hasAVP, attack, random, attackRate);
        }

        invader.lastProcessingTime = block.timestamp;
    }

    function SuccessfulAttack(HiveInfo storage _hive, HiveDayInfo storage _hiveDay, AttackInfo storage _attack, uint256 _random, uint256 _attackRate) private {
        uint256 damage = 0;
        uint256 stolenVenom = 0;

        if (_random < 5 * _attackRate) {
            damage = 2 * (1000 - _hiveDay.defense);
            stolenVenom = _hive.yieldVenom.mul(2).div(100);
            _attack.statuses.push(0);
        } else if (_random < 55 * _attackRate) {
            damage = 1000 - _hiveDay.defense;
            stolenVenom = _hive.yieldVenom.div(100);
            _attack.statuses.push(1);
        } else {
            damage = 1000 - _hiveDay.defense;
            _attack.statuses.push(2);
        }

        _hive.health = _hive.health < damage? 0 : _hive.health - damage;
        _hive.yieldVenom -= stolenVenom;
        _attack.damage += damage;
        _attack.timestamps.push(block.timestamp);
        _attack.damages.push(damage);

        Venom.accountMint(msg.sender, stolenVenom);
    }

    function FailedAttack(InvaderInfo storage _invader, bool _hasAVP, AttackInfo storage _attack, uint256 _random, uint256 _attackRate) private {
        if (_random >= 10000 - 5 * _attackRate) {
            _invader.status = _hasAVP? 0 : 2;
            _attack.statuses.push(_hasAVP? 3 : 5);
        } else if (_random >= 10000 - 65 * _attackRate) {
            _invader.status = 1;
            _attack.statuses.push(4);
        } else {
            _invader.status = 0;
            _attack.statuses.push(5);
        }
        _attack.timestamps.push(block.timestamp);
        _attack.damages.push(0);
    }

    function getRandomNumber(uint256 _number) private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % _number;
    }

    function getTotalDividendFromHive(uint256 _hid) public view returns (uint256) {
        HiveInfo storage hive = hiveInfo[_hid];
        uint256 totalDividend = 0;
        for (uint256 index = 0; index < hive.hornets.length; index++) {
            HornetInfo storage hornet = hornetInfo[hive.hornets[index]];
            totalDividend += CalculateDayOfHive(_hid) - hornet.stakedDay;
        }
        return totalDividend;
    }

    function getYieldFromHornet(uint256 _hid, uint256 _hornet) public view returns(uint256) {
        HiveInfo storage hive = hiveInfo[_hid];
        HornetInfo storage hornet = hornetInfo[_hornet];
        return hive.yieldVenom.mul(CalculateDayOfHive(_hid) - hornet.stakedDay).div(getTotalDividendFromHive(_hid));
    }

    function onERC721Received( address , address , uint256 , bytes calldata  ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}