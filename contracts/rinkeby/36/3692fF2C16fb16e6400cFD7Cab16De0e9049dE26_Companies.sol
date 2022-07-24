pragma solidity ^0.8.12;
// SPDX-License-Identifier: MIT

/**
 * @title Regular Companies v1.0 
 */

import "./Random.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// "special" companies are for a set of Regular IDs that share a trait, like McD's workers
// "not-special" companies get assigned to regular IDs randomly.

contract Companies is AccessControl {
    using Random for Random.Manifest;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public constant SALARY_DECIMALS = 2;
    uint public SALARY_MULTIPLIER = 100;                   // basis points

    struct Company {     
        uint128 baseSalary;   
        uint128 capacity;        
    }

    Company[60] companies;                                  // Companies by ID
    uint16[60] indexes;                                     // the starting index of the company in array of job IDs
    uint16[60] counts;
    Random.Manifest private mainDeck;                       // Card deck for non-special companies
    mapping(uint => Random.Manifest) private specialDecks;  // Card decks for special companies
    mapping(uint => uint) private specialCompanyIds;        // Company ID by special reg ID
    uint specialCompanyIdFlag;                              // Company ID for the first special company in the array
    uint[] _tempArray;                                      // used for parsing special IDs
    mapping(uint => bool) managerIds;                       // IDs of all McD's manager regs
    mapping(uint => string) names;                          // Company Names

    event jobIDCreated (uint256 regularId, uint newJobId, uint companyId, address sender);
    
	constructor() {
	    _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, msg.sender);

// Save Names

        names[0] = "RNN News";
        names[1] = "AAAARP";
        names[2] = "Petstore";
        names[3] = "Foodtime";
        names[4] = "Hats";
        names[5] = "Bed Bath & Bodyworks";
        names[6] = "Bugs Inc.";
        names[7] = "Autoz";
        names[8] = "Office Dept.";
        names[9] = "Express";
        names[10] = "Totally Wine";
        names[11] = "Y'all";
        names[12] = "5 O'clockville";
        names[13] = "Nrfthrup Grrmng";
        names[14] = "Mall Corp.";
        names[15] = "Ice Creams";
        names[16] = "Thanky Candles";
        names[17] = "Hotella";
        names[18] = "Berkshire Thataway";
        names[19] = "Kopies";
        names[20] = "Sprayers";
        names[21] = "'Onuts";
        names[22] = "Tax Inc.";
        names[23] = "Khols";
        names[24] = "Black Pebble";
        names[25] = "Haircuts Inc.";
        names[26] = "Global Gas";
        names[27] = "Block";
        names[28] = "Eyeglasses";
        names[29] = "Books & Mags";
        names[30] = "Meme";
        names[31] = "Coin";
        names[32] = "Wonder";
        names[33] = "iSecurity";
        names[34] = "Dairy Lady";
        names[35] = "Big Deal MGMT";
        names[36] = "Spotlight Talent";
        names[37] = "Rock Solid Insurance";
        names[38] = "Safe Shield Insurance";
        names[39] = "Bit";
        names[40] = "Whoppy Jrs.";
        names[41] = "WGMI Inc.";
        names[42] = "Global International";
        names[43] = "N.E.X.T. Rugs";
        names[44] = "Alpha Limited";
        names[45] = "Best Shack";
        names[46] = "Partners & Partners";
        names[47] = "Boss E-systems";
        names[48] = "Blockbusters";
        names[49] = "Hexagon Research Group";
        names[50] = "Crabby Shack";
        names[51] = "Dollar Store";
        names[52] = "UP Only";
        names[53] = "Frito Pay";
        names[54] = "Hot Pockets";
        names[55] = "Spooky";
        names[56] = "GM";
        names[57] = "McDanny's";
        names[58] = "Wendy's";
        names[59] = "Party Place";     
      
// Init companies
        
        companies[0] =  Company({ capacity : 212, baseSalary : 1950 });
        companies[1] =  Company({ capacity : 350, baseSalary : 1300 });
        companies[2] =  Company({ capacity : 120, baseSalary : 3725 });
        companies[3] =  Company({ capacity : 144, baseSalary : 3175 });
        companies[4] =  Company({ capacity : 168, baseSalary : 2375 });
        companies[5] =  Company({ capacity : 160, baseSalary : 2475 });
        companies[6] =  Company({ capacity : 100, baseSalary : 4400 });
        companies[7] =  Company({ capacity : 184, baseSalary : 2200 });
        companies[8] =  Company({ capacity : 500, baseSalary : 1025 });
        companies[9] =  Company({ capacity : 188, baseSalary : 2150 });
        companies[10] = Company({ capacity : 140, baseSalary : 3250 });
        companies[11] = Company({ capacity :  96, baseSalary : 4575 });
        companies[12] = Company({ capacity :  50, baseSalary : 7550 });
        companies[13] = Company({ capacity : 192, baseSalary : 2100 });
        companies[14] = Company({ capacity :  92, baseSalary : 4750 });
        companies[15] = Company({ capacity : 156, baseSalary : 2525 });
        companies[16] = Company({ capacity : 176, baseSalary : 2275 });
        companies[17] = Company({ capacity : 148, baseSalary : 3100 });
        companies[18] = Company({ capacity : 200, baseSalary : 2050 });
        companies[19] = Company({ capacity : 136, baseSalary : 3350 });
        companies[20] = Company({ capacity : 204, baseSalary : 2000 });
        companies[21] = Company({ capacity : 104, baseSalary : 4250 });
        companies[22] = Company({ capacity : 218, baseSalary : 1900 });
        companies[23] = Company({ capacity :  57, baseSalary : 6675 });
        companies[24] = Company({ capacity : 196, baseSalary : 2075 });
        companies[25] = Company({ capacity : 206, baseSalary : 2000 });
        companies[26] = Company({ capacity : 210, baseSalary : 1950 });
        companies[27] = Company({ capacity :  88, baseSalary : 4950 });
        companies[28] = Company({ capacity : 214, baseSalary : 1925 });
        companies[29] = Company({ capacity : 242, baseSalary : 1750 });
        companies[30] = Company({ capacity : 124, baseSalary : 3625 });
        companies[31] = Company({ capacity : 164, baseSalary : 2425 });
        companies[32] = Company({ capacity : 116, baseSalary : 3850 });
        companies[33] = Company({ capacity : 180, baseSalary : 2225 });
        companies[34] = Company({ capacity : 172, baseSalary : 2325 });
        companies[35] = Company({ capacity : 132, baseSalary : 3425 });
        companies[36] = Company({ capacity : 152, baseSalary : 3025 });
        companies[37] = Company({ capacity : 450, baseSalary : 1100 });
        companies[38] = Company({ capacity : 600, baseSalary : 900 });
        companies[39] = Company({ capacity : 112, baseSalary : 3975 });
        companies[40] = Company({ capacity :  65, baseSalary : 5900 });
        companies[41] = Company({ capacity :  76, baseSalary : 5500 });
        companies[42] = Company({ capacity :  80, baseSalary : 5400 });
        companies[43] = Company({ capacity :  84, baseSalary : 5150 });
        companies[44] = Company({ capacity : 290, baseSalary : 1500 });
        companies[45] = Company({ capacity : 108, baseSalary : 4100 });
        companies[46] = Company({ capacity : 276, baseSalary : 1575 });
        companies[47] = Company({ capacity : 400, baseSalary : 1200 });
        companies[48] = Company({ capacity :  53, baseSalary : 7150 });
        companies[49] = Company({ capacity : 300, baseSalary : 1475 });
        companies[50] = Company({ capacity :  69, baseSalary : 5875 });
        companies[51] = Company({ capacity :  72, baseSalary : 5650 });
        companies[52] = Company({ capacity : 208, baseSalary : 1975 });
        companies[53] = Company({ capacity : 128, baseSalary : 3525 });
        companies[54] = Company({ capacity :  73, baseSalary : 5575 });

// Specials companies

        // 55 Spooky
        _tempArray = [
            379, 391, 874, 1004, 1245, 1258, 1398, 1584, 1869, 1940, 1952, 2269, 2525, 2772, 3055, 3455, 3472, 3541, // 30 Clowns
            3544, 3607, 3617, 4103, 4117, 4149, 4195, 4230, 4425, 5065, 5101, 5188,
            4, 27, 48, 101, 136, 143, 157, 165, 172, 175, 226, 277, 388, 389, 418, 420, 444, 457, 493, 516, 518,  // 31 Heavy Makeup 
            610, 638, 679, 681, 703, 743, 784, 867, 917, 959
        ];
        parseSpecialRegIDs(55,_tempArray, 6250); 

        // 56 GM
        _tempArray = [
            4466, 4684, 5342, 5437, 5932, 6838, 8043, 1175, 1274, 2005, 2497, 2592, 3063, 3285, 3300, 3316,   // 32 Devils
            3454, 3983, 4541, 4856, 5171, 5219, 5265, 6643, 6719, 6982, 7147, 7303, 8012, 8944, 9644, 9822,
            1013, 1032, 1042, 1084, 1127, 1142, 1196, 1234, 1279, 1295, 1296, 1297, 1310, 1323, 1356, 1390, 1405  // 17 Heavy makeup
        ];
        parseSpecialRegIDs(56,_tempArray, 7700);

        // 57 McDanny's
        _tempArray = [
            1617, 1808, 2149, 2632, 2833, 2847, 3301, 3524, 4822, 5139, 5735, 5906, 5946, 6451, 6663, 6762, 6831,  // McD's Workers + Managers
            7278, 7519, 8365, 9434, 64, 488, 642, 946, 1014, 1650, 1823, 1949, 2178, 2593, 2992, 3070, 3331, 3745, 
            3944, 3961, 4030, 4070, 4090, 4197, 4244, 4719, 5551, 5761, 5779, 5895, 6044, 6048, 6276, 6599, 6681, 
            6832, 6873, 6889, 7124, 7550, 7975, 8130, 8579, 8599, 8689, 8784, 8794, 8903, 9053, 9205, 9254, 9407, 9994
        ];
        parseSpecialRegIDs(57,_tempArray, 8250); 

        // 58 Wendy's
        _tempArray = [
            317, 456, 878, 1588, 2702, 2974, 3047, 3224, 3308, 3441, 4082, 4107, 5490, 5574, 5622, 6232, 6317,  // Wendys Workers
            6350, 6404, 6539, 7654, 7947, 7961, 8248, 8400, 8437, 8643, 8667, 8728, 9221, 9611, 9709, 9754, 9950
        ];
        parseSpecialRegIDs(58,_tempArray, 7900);

        // 59 Party Place - 25 Clowns + 26 heavy makeup
        _tempArray = [
            5494, 5845, 6016, 6042, 6073, 6109, 6436, 6649, 7092, 7574, 7863, 8077, 8110, 8326, 8359, 8480, 8629,  // 25 Clowns
            8825, 9303, 9319, 9339, 9770, 9800, 9858, 9870,
            1440, 1482, 1566, 1596, 1598, 1660, 1663, 1695, 1700,   // 26 heavy makeup
            1708, 1905, 1929, 1986, 2018, 2026, 2037, 2067, 2097, 2125, 2148, 2176, 2207, 2247, 2262, 2347, 2494
        ];
        parseSpecialRegIDs(59,_tempArray, 7425);

// McD's managers

        // These Ids are only used for seniority level bonus, on mint
        _tempArray = [1617, 1808, 2149, 2632, 2833, 2847, 3301, 3524, 4822, 5139, 5735, 5906, 5946, 6451, 6663,  // 21 Managers
        6762, 6831, 7278, 7519, 8365, 9434 ]; 

        for (uint i = 0;i < _tempArray.length;i++){
            managerIds[_tempArray[i]] = true;
        }

//  
        specialCompanyIdFlag = 55;
        
        uint jobCountNotSpecial = 0;
        for (uint i = 0; i < specialCompanyIdFlag; i++) {
            jobCountNotSpecial += companies[i].capacity;
        }
        mainDeck.setup(jobCountNotSpecial);

        uint jobCountSpecial = 0;
        for (uint i = specialCompanyIdFlag; i < numCompanies(); i++) {
            jobCountSpecial += companies[i].capacity;
        }

        uint _startIndex = 0;
        for (uint i = 0; i < numCompanies(); i++) {
            indexes[i] = uint16(_startIndex);
            _startIndex += companies[i].capacity;
        }
	}

// Admin Functions

    function makeNewJob(uint _regularId) public onlyRole(MINTER_ROLE) returns (uint, uint) {
        uint _pull;
        uint _specialCompanyId = specialCompanyIds[_regularId];
        uint _newJobId;
        if (_specialCompanyId == 0) {   
            // If Regular id is NOT special
            _pull = mainDeck.draw();
            uint _companyId = getCompanyId(_pull);
            counts[_companyId]++;
            emit jobIDCreated(_regularId, add1(_pull), _companyId, msg.sender);
            return (add1(_pull), _companyId);             
        } else {                        
            // If Regular id IS special
            _pull = specialDecks[_specialCompanyId].draw();
            _newJobId = _pull + indexes[_specialCompanyId];
            counts[_specialCompanyId]++;
            emit jobIDCreated(_regularId, add1(_newJobId), _specialCompanyId, msg.sender);
            return (add1(_newJobId), _specialCompanyId); 
        } 
    }

    function updateCompany(uint _companyId, uint128 _baseSalary, string memory _name) public onlyRole(MINTER_ROLE)  {
        companies[_companyId].baseSalary = _baseSalary;
        names[_companyId] = _name;
    } 

    function setSalaryMultiplier(uint _basispoints) public onlyRole(MINTER_ROLE) {
        SALARY_MULTIPLIER = _basispoints;
    }

// View Functions

    function getCount(uint _companyId) public view returns (uint) {
        return counts[_companyId];
    }

    function getBaseSalary(uint _companyId) public view returns (uint) {
        return companies[_companyId].baseSalary * SALARY_MULTIPLIER / 100;
    }

    function getSpread(uint _companyId) public pure returns (uint) {
        uint _nothing = 12345;
        return uint(keccak256(abi.encodePacked(_companyId + _nothing))) % 40;
    }

    function getCapacity(uint _companyId) public view returns (uint) {
        return companies[_companyId].capacity;
    }

    function numCompanies() public view returns (uint) {
        return companies.length;
    }

    function isManager(uint _regId) public view returns (bool) {
        return managerIds[_regId];
    }

    function maxJobIds() public view returns (uint) {
        uint _total = 0;
        for (uint i = 0; i < numCompanies(); i++) {
            _total += companies[i].capacity;
        }
        return _total;
    }

    function getName(uint _companyId) public view returns (string memory) {
        return names[_companyId];
    }

// Internal

    function getCompanyId(uint _jobId) internal view returns (uint) {
        uint _numCompanies = companies.length;
        uint i;
        for (i = 0; i < _numCompanies -1; i++) {
            if (_jobId >= indexes[i] && _jobId < indexes[i+1])
                break;
        }
        return i;
    }

    function parseSpecialRegIDs(uint _companyId, uint[] memory _ids, uint _baseSalary) internal {
        for (uint i = 0;i < _ids.length; i++) {
            specialCompanyIds[_ids[i]] = _companyId;
        }
        companies[_companyId] = Company({ capacity : uint128(_ids.length), baseSalary : uint128(_baseSalary) }); 
        specialDecks[_companyId].setup(_ids.length);
    }

    function add1(uint _x) internal pure returns (uint) {
        return _x + 1;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Random {
    function random() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)) ;
    }

    struct Manifest {
        uint256[] _data;
    }

    function setup(Manifest storage self, uint256 length) internal {
        uint256[] storage data = self._data;

        require(data.length == 0, "cannot-setup-during-active-draw");
        assembly { sstore(data.slot, length) }
    }

    function draw(Manifest storage self) internal returns (uint256) {
        return draw(self, random());
    }

    function draw(Manifest storage self, bytes32 seed) internal returns (uint256) {
        uint256[] storage data = self._data;

        uint256 l = data.length;
        uint256 i = uint256(seed) % l;
        uint256 x = data[i];
        uint256 y = data[--l];
        if (x == 0) { x = i + 1;   }
        if (y == 0) { y = l + 1;   }
        if (i != l) { data[i] = y; }
        data.pop();
        return x - 1;
    }

    function put(Manifest storage self, uint256 i) internal {
        self._data.push(i + 1);
    }

    function remaining(Manifest storage self) internal view returns (uint256) {
        return self._data.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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