pragma solidity ^0.8.12;
// SPDX-License-Identifier: MIT

/**
 * @title Regular Companies v1.0 
 */

import "./Random.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// "special" companies are for a set of Regular IDs that share a trait, like McD's workers
// "not-special" companies get assigned to regular IDs randomly.

contract Companies is AccessControl {
    using Random for Random.Manifest;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public constant SALARY_DECIMALS = 2;

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
    uint jobCountNotSpecial;                                // Total count of non-special jobs
    uint specialCompanyIdFlag;                              // Company ID for the first special company in the array
    uint[] _tempArray;                                      // used for parsing special IDs
    mapping(uint => bool) managerIds;                       // IDs of all McD's manager regs
    mapping(uint => string) names;                          // Company Names

    // EnumerableSet.UintSet[60] sets;                      // maintain list of members

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
        names[6] = "Bugs";
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
        names[43] = "Next Rugs";
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
        
        companies[0] = Company({ capacity : 212, baseSalary : 972 });
        companies[1] = Company({ capacity : 350, baseSalary : 656 });
        companies[2] = Company({ capacity : 120, baseSalary : 1867 });
        companies[3] = Company({ capacity : 144, baseSalary : 1589 });
        companies[4] = Company({ capacity : 168, baseSalary : 1182 });
        companies[5] = Company({ capacity : 160, baseSalary : 1233 });
        companies[6] = Company({ capacity : 100, baseSalary : 2200 });
        companies[7] = Company({ capacity : 184, baseSalary : 1094 });
        companies[8] = Company({ capacity : 500, baseSalary : 510 });
        companies[9] = Company({ capacity : 188, baseSalary : 1074 });
        companies[10] = Company({ capacity : 140, baseSalary : 1629 });
        companies[11] = Company({ capacity : 96, baseSalary : 2283 });
        companies[12] = Company({ capacity : 50, baseSalary : 3780 });
        companies[13] = Company({ capacity : 192, baseSalary : 1055 });
        companies[14] = Company({ capacity : 92, baseSalary : 2374 });
        companies[15] = Company({ capacity : 156, baseSalary : 1260 });
        companies[16] = Company({ capacity : 176, baseSalary : 1136 });
        companies[17] = Company({ capacity : 148, baseSalary : 1551 });
        companies[18] = Company({ capacity : 200, baseSalary : 1020 });
        companies[19] = Company({ capacity : 136, baseSalary : 1671 });
        companies[20] = Company({ capacity : 204, baseSalary : 1003 });
        companies[21] = Company({ capacity : 104, baseSalary : 2123 });
        companies[22] = Company({ capacity : 218, baseSalary : 950 });
        companies[23] = Company({ capacity : 57, baseSalary : 3338 });
        companies[24] = Company({ capacity : 196, baseSalary : 1037 });
        companies[25] = Company({ capacity : 206, baseSalary : 995 });
        companies[26] = Company({ capacity : 210, baseSalary : 980 });
        companies[27] = Company({ capacity : 88, baseSalary : 2473 });
        companies[28] = Company({ capacity : 214, baseSalary : 964 });
        companies[29] = Company({ capacity : 242, baseSalary : 872 });
        companies[30] = Company({ capacity : 124, baseSalary : 1813 });
        companies[31] = Company({ capacity : 164, baseSalary : 1207 });
        companies[32] = Company({ capacity : 116, baseSalary : 1924 });
        companies[33] = Company({ capacity : 180, baseSalary : 1114 });
        companies[34] = Company({ capacity : 172, baseSalary : 1158 });
        companies[35] = Company({ capacity : 132, baseSalary : 1715 });
        companies[36] = Company({ capacity : 152, baseSalary : 1516 });
        companies[37] = Company({ capacity : 450, baseSalary : 548 });
        companies[38] = Company({ capacity : 600, baseSalary : 453 });
        companies[39] = Company({ capacity : 112, baseSalary : 1986 });
        companies[40] = Company({ capacity : 65, baseSalary : 2949 });
        companies[41] = Company({ capacity : 76, baseSalary : 2747 });
        companies[42] = Company({ capacity : 80, baseSalary : 2700 });
        companies[43] = Company({ capacity : 84, baseSalary : 2581 });
        companies[44] = Company({ capacity : 290, baseSalary : 756 });
        companies[45] = Company({ capacity : 108, baseSalary : 2052 });
        companies[46] = Company({ capacity : 276, baseSalary : 786 });
        companies[47] = Company({ capacity : 400, baseSalary : 595 });
        companies[48] = Company({ capacity : 53, baseSalary : 3576 });
        companies[49] = Company({ capacity : 300, baseSalary : 373 });
        companies[50] = Company({ capacity : 69, baseSalary : 2944 });
        companies[51] = Company({ capacity : 72, baseSalary : 2829 });
        companies[52] = Company({ capacity : 208, baseSalary : 987 });
        companies[53] = Company({ capacity : 128, baseSalary : 1763 });
        companies[54] = Company({ capacity : 73, baseSalary : 2793 });

// Specials companies

        // 55 Spooky
        _tempArray = [
            379, 391, 874, 1004, 1245, 1258, 1398, 1584, 1869, 1940, 1952, 2269, 2525, 2772, 3055, 3455, 3472, 3541, // 30 Clowns
            3544, 3607, 3617, 4103, 4117, 4149, 4195, 4230, 4425, 5065, 5101, 5188,
            4, 27, 48, 101, 136, 143, 157, 165, 172, 175, 226, 277, 388, 389, 418, 420, 444, 457, 493, 516, 518,  // 31 Heavy Makeup 
            610, 638, 679, 681, 703, 743, 784, 867, 917, 959
        ];
        parseSpecialRegIDs(55,_tempArray, 3131); // baseSalary = 3131

        // 56 GM
        _tempArray = [
            4466, 4684, 5342, 5437, 5932, 6838, 8043, 1175, 1274, 2005, 2497, 2592, 3063, 3285, 3300, 3316,   // 32 Devils
            3454, 3983, 4541, 4856, 5171, 5219, 5265, 6643, 6719, 6982, 7147, 7303, 8012, 8944, 9644, 9822,
            1013, 1032, 1042, 1084, 1127, 1142, 1196, 1234, 1279, 1295, 1296, 1297, 1310, 1323, 1356, 1390, 1405  // 17 Heavy makeup
        ];
        parseSpecialRegIDs(56,_tempArray, 3853); // baseSalary = 3853

        // 57 McDanny's
        _tempArray = [
            1617, 1808, 2149, 2632, 2833, 2847, 3301, 3524, 4822, 5139, 5735, 5906, 5946, 6451, 6663, 6762, 6831,  // McD's Workers + Managers
            7278, 7519, 8365, 9434, 64, 488, 642, 946, 1014, 1650, 1823, 1949, 2178, 2593, 2992, 3070, 3331, 3745, 
            3944, 3961, 4030, 4070, 4090, 4197, 4244, 4719, 5551, 5761, 5779, 5895, 6044, 6048, 6276, 6599, 6681, 
            6832, 6873, 6889, 7124, 7550, 7975, 8130, 8579, 8599, 8689, 8784, 8794, 8903, 9053, 9205, 9254, 9407, 9994
        ];
        parseSpecialRegIDs(57,_tempArray, 4127); // baseSalary = 4127

        // 58 Wendy's
        _tempArray = [
            317, 456, 878, 1588, 2702, 2974, 3047, 3224, 3308, 3441, 4082, 4107, 5490, 5574, 5622, 6232, 6317,  // Wendys Workers
            6350, 6404, 6539, 7654, 7947, 7961, 8248, 8400, 8437, 8643, 8667, 8728, 9221, 9611, 9709, 9754, 9950
        ];
        parseSpecialRegIDs(58,_tempArray, 3954); // baseSalary = 3954

        // 59 Party Place - 25 Clowns + 26 heavy makeup
        _tempArray = [
            5494, 5845, 6016, 6042, 6073, 6109, 6436, 6649, 7092, 7574, 7863, 8077, 8110, 8326, 8359, 8480, 8629,  // 25 Clowns
            8825, 9303, 9319, 9339, 9770, 9800, 9858, 9870,
            1440, 1482, 1566, 1596, 1598, 1660, 1663, 1695, 1700,   // 26 heavy makeup
            1708, 1905, 1929, 1986, 2018, 2026, 2037, 2067, 2097, 2125, 2148, 2176, 2207, 2247, 2262, 2347, 2494
        ];
        parseSpecialRegIDs(59,_tempArray, 3709); // baseSalary = 3709

// McD's managers

        // These Ids are only used for seniority level bonus, on mint
        _tempArray = [1617, 1808, 2149, 2632, 2833, 2847, 3301, 3524, 4822, 5139, 5735, 5906, 5946, 6451, 6663,  // 21 Managers
        6762, 6831, 7278, 7519, 8365, 9434 ]; 

        for (uint i = 0;i < _tempArray.length;i++){
            managerIds[_tempArray[i]] = true;
        }

//  
        specialCompanyIdFlag = 55;
        
        jobCountNotSpecial = 0;
        for (uint i = 0; i < specialCompanyIdFlag; i++)
            jobCountNotSpecial += companies[i].capacity;
        mainDeck.setup(jobCountNotSpecial);

        uint jobCountSpecial = 0;
        for (uint i = specialCompanyIdFlag; i < numCompanies(); i++)
            jobCountSpecial += companies[i].capacity;

        uint _startIndex = 0;
        for (uint i = 0; i < numCompanies(); i++) {
            indexes[i] = uint16(_startIndex);
            _startIndex += companies[i].capacity;
        }
	}

// ADMIN FUNCTIONS

    // keep count of company members
    function makeNewJob(uint _regularId) public onlyRole(MINTER_ROLE) returns (uint, uint) {
        uint _pull;
        uint _specialCompanyId = specialCompanyIds[_regularId];
        uint _newJobId;
        // console.log(_regularId);
        if (_specialCompanyId == 0) {     // If Regular id is NOT special
            _pull = mainDeck.draw();
            uint _companyId = getCompanyId(_pull);
            counts[_companyId]++;
            emit jobIDCreated(_regularId, _pull, _companyId, msg.sender);
            return (_pull, _companyId);
        } else {                          // If Regular id IS special
            _pull = specialDecks[_specialCompanyId].draw();
            _newJobId = _pull + indexes[_specialCompanyId];
            counts[_specialCompanyId]++;
            emit jobIDCreated(_regularId, _newJobId, _specialCompanyId, msg.sender);
            return (_newJobId, _specialCompanyId);
        } 
    }

    // // record all member IDs of companies
    // function makeNewJob(uint _regularId) public onlyRole(MINTER_ROLE) returns (uint, uint) {
    //     uint _specialCompanyId = specialCompanyIds[_regularId];

    //     if (_specialCompanyId == 0) {     // If Regular id is NOT special
    //         uint _pull = mainDeck.draw();
    //         uint _companyId = getCompanyId(_pull);
    //         sets[_companyId].add(_pull);
    //         emit jobIDCreated(_regularId, _pull, _companyId, msg.sender);
    //         return (_pull, _companyId);
    //     } else {                          // If Regular id IS special
    //         uint _newJobId = specialDecks[_specialCompanyId].draw() + indexes[_specialCompanyId];
    //         sets[_specialCompanyId].add(_newJobId);
    //         emit jobIDCreated(_regularId, _newJobId, _specialCompanyId, msg.sender);
    //         return (_newJobId, _specialCompanyId);
    //     } 
    // }

    function updateCompany(uint _companyId, uint128 _baseSalary, string memory _name) public onlyRole(MINTER_ROLE)  {
        companies[_companyId].baseSalary = _baseSalary;
        names[_companyId] = _name;
    } 

// View Functions

    function getCompanyId(uint _jobId) public view returns (uint) {
        uint _numCompanies = companies.length;
        uint i;
        for (i = 0; i < _numCompanies -1; i++) {
            if (_jobId >= indexes[i] && _jobId < indexes[i+1])
                break;
        }
        return i;
    }

    function getCount(uint _companyId) public view returns (uint) {
        return counts[_companyId];
    }

    function getBaseSalary(uint _companyId) public view returns (uint) {
        return companies[_companyId].baseSalary;
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

    function parseSpecialRegIDs(uint _companyId, uint[] memory _ids, uint _baseSalary) internal {
        for (uint i = 0;i < _ids.length; i++) {
            specialCompanyIds[_ids[i]] = _companyId;
        }
        companies[_companyId] = Company({ capacity : uint128(_ids.length), baseSalary : uint128(_baseSalary) }); 
        specialDecks[_companyId].setup(_ids.length);
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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