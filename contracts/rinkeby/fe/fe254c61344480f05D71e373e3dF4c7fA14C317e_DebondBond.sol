// SPDX-License-Identifier: MIT


pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IDebondBond.sol";


contract DebondBond is IDebondBond, AccessControl {

    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    /**
    * @notice this Struct is representing the Nonce properties as an object
    *         and can be retrieve by the nonceId (within a class)
    */
    struct Nonce {
        uint256 id;
        bool exists;
        uint256 _activeSupply;
        uint256 _burnedSupply;
        uint256 _redeemedSupply;
        uint256 maturityDate;
        uint256 issuanceDate;
        uint256 liqT;
        uint256[] infos;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(address => bool) hasBalance;
    }

    /**
    * @notice this Struct is representing the Class properties as an object
    *         and can be retrieve by the classId
    */
    struct Class {
        uint256 id;
        bool exists;
        string symbol;
        uint256[] infos;
        IData.InterestRateType interestRateType;
        address tokenAddress;
        uint256 periodTimestamp;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(address => mapping(uint256 => bool)) noncesPerAddress;
        mapping(address => uint256[]) noncesPerAddressArray;
        uint256[] nonceIds;
        mapping(uint256 => Nonce) nonces; // from nonceId given
    }

    mapping(uint256 => Class) internal classes; // from classId given
    string[] public classInfoDescriptions; // mapping with class.infos
    string[] public nonceInfoDescriptions; // mapping with nonce.infos
    mapping(address => mapping(uint256 => bool)) classesPerAddress;
    mapping(address => uint256[]) public classesPerAddressArray;


    bool public _isActive;

    constructor(
        address DBIT,
        address USDC,
        address USDT,
        address DAI
    ) {
        _isActive = true;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        createClass(0, "D/BIT", IData.InterestRateType.FixedRate, DBIT, 60);
        createClass(1, "USDC", IData.InterestRateType.FixedRate, USDC, 60);
        createClass(2, "USDT", IData.InterestRateType.FixedRate, USDT, 60);
        createClass(3, "DAI", IData.InterestRateType.FixedRate, DAI, 60);
    }


    function isActive() external view returns (bool) {
        return _isActive;
    }

    // WRITE

    function transferFrom(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) public virtual override {
        require(msg.sender == from || isApprovedFor(from, msg.sender, classId), "ERC3475: caller is not owner nor approved");
        _transferFrom(from, to, classId, nonceId, amount);
        emit Transfer(msg.sender, from, to, classId, nonceId, amount);
    }


    function issue(address to, uint256 classId, uint256 nonceId, uint256 amount) external override onlyRole(ISSUER_ROLE) {
        require(classExists(classId), "ERC3475: only issue bond that has been created");
        Class storage class = classes[classId];

        Nonce storage nonce = class.nonces[nonceId];
        require(nonceId == nonce.id, "ERC-3475: nonceId given not found!");

        require(to != address(0), "ERC3475: can't transfer to the zero address");
        _issue(to, classId, nonceId, amount);

        if(!classesPerAddress[to][classId]) {
            classesPerAddressArray[to].push(classId);
            classesPerAddress[to][classId] = true;
        }

        if(!class.noncesPerAddress[to][nonceId]) {
            class.noncesPerAddressArray[to].push(nonceId);
            class.noncesPerAddress[to][nonceId] = true;
        }
        emit Issue(msg.sender, to, classId, nonceId, amount);
    }

    function classExists(uint256 classId) public view returns (bool) {
        return classes[classId].exists;
    }

    function nonceExists(uint256 classId, uint256 nonceId) public view returns (bool) {
        return classes[classId].nonces[nonceId].exists;
    }

    function createClass(uint256 classId, string memory _symbol, IData.InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) public override {
        require(!classExists(classId), "ERC3475: cannot create a class that already exists");
        Class storage class = classes[classId];
        class.id = classId;
        class.exists = true;
        class.symbol = _symbol;
        class.interestRateType = interestRateType;
        class.tokenAddress = tokenAddress;
        class.periodTimestamp = periodTimestamp;
    }

    function createNonce(uint256 classId, uint256 nonceId, uint256 _maturityDate, uint256 liqT) external override onlyRole(ISSUER_ROLE) {
        require(classExists(classId), "ERC3475: only issue bond that has been created");
        Class storage class = classes[classId];

        Nonce storage nonce = class.nonces[nonceId];
        require(!nonce.exists, "Error ERC-3475: nonceId exists!");

        nonce.id = nonceId;
        nonce.exists = true;
        nonce.maturityDate = _maturityDate;
        nonce.issuanceDate = block.timestamp;
        nonce.liqT = liqT;
    }

    function redeem(address from, uint256 classId, uint256 nonceId, uint256 amount) external override onlyRole(ISSUER_ROLE) {
        require(from != address(0), "ERC3475: can't transfer to the zero address");
        require(isRedeemable(classId, nonceId), "Bond is not redeemable");
        _redeem(from, classId, nonceId, amount);
        emit Redeem(msg.sender, from, classId, nonceId, amount);
    }


    function burn(address from, uint256 classId, uint256 nonceId, uint256 amount) external override onlyRole(ISSUER_ROLE) {
        require(from != address(0), "ERC3475: can't transfer to the zero address");
        _burn(from, classId, nonceId, amount);
        emit Burn(msg.sender, from, classId, nonceId, amount);
    }


    function approve(address spender, uint256 classId, uint256 nonceId, uint256 amount) external override {
        classes[classId].nonces[nonceId].allowances[msg.sender][spender] = amount;
    }


    function setApprovalFor(address operator, uint256 classId, bool approved) public override {
        classes[classId].operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalFor(msg.sender, operator, classId, approved);
    }


    function batchApprove(address spender, uint256[] calldata classIds, uint256[] calldata nonceIds, uint256[] calldata amounts) external {
        require(classIds.length == nonceIds.length && classIds.length == amounts.length, "ERC3475 Input Error");
        for(uint256 i = 0; i < classIds.length; i++) {
            classes[classIds[i]].nonces[nonceIds[i]].allowances[msg.sender][spender] = amounts[i];
        }
    }
    // READS


    function totalSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._activeSupply + classes[classId].nonces[nonceId]._redeemedSupply + classes[classId].nonces[nonceId]._burnedSupply;
    }


    function activeSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._activeSupply;
    }


    function burnedSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._burnedSupply;
    }


    function redeemedSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._burnedSupply;
    }


    function balanceOf(address account, uint256 classId, uint256 nonceId) public override view returns (uint256) {
        require(account != address(0), "ERC3475: balance query for the zero address");

        return classes[classId].nonces[nonceId].balances[account];
    }


    function symbol(uint256 classId) public view override returns (string memory) {
        Class storage class = classes[classId];
        return class.symbol;
    }


    function classInfos(uint256 classId) public view override returns (uint256[] memory) {
        return classes[classId].infos;
    }


    function nonceInfos(uint256 classId, uint256 nonceId) public view override returns (uint256[] memory) {
        return classes[classId].nonces[nonceId].infos;
    }

    function bondDetails(uint256 classId, uint256 nonceId) public view override returns (string memory _symbol, IData.InterestRateType _interestRateType, address _tokenAddress, uint256 _periodTimestamp, uint256 _issuanceDate, uint256 _maturityDate) {
        Class storage class =  classes[classId];
        Nonce storage nonce =  class.nonces[nonceId];

        _symbol = class.symbol;
        _interestRateType = class.interestRateType;
        _tokenAddress = class.tokenAddress;
        _periodTimestamp = class.periodTimestamp;
        _issuanceDate = nonce.issuanceDate;
        _maturityDate = nonce.maturityDate;

        return (_symbol, _interestRateType, _tokenAddress, _periodTimestamp, _issuanceDate, _maturityDate);
    }



    function classInfoDescription(uint256 classInfo) external view returns (string memory) {
        return classInfoDescriptions[classInfo];
    }

    function nonceInfoDescription(uint256 nonceInfo) external view returns (string memory) {
        return nonceInfoDescriptions[nonceInfo];
    }


    function isRedeemable(uint256 classId, uint256 nonceId) public override view returns (bool) {
        return classes[classId].nonces[nonceId].maturityDate <= block.timestamp;
    }


    function allowance(address owner, address spender, uint256 classId, uint256 nonceId) external view returns (uint256) {
        return classes[classId].nonces[nonceId].allowances[owner][spender];
    }


    function isApprovedFor(address owner, address operator, uint256 classId) public view virtual override returns (bool) {
        return classes[classId].operatorApprovals[owner][operator];
    }


    function getNoncesPerAddress(address addr, uint256 classId) public view returns (uint256[] memory) {
        return classes[classId].noncesPerAddressArray[addr];
    }

    function batchActiveSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchActiveSupply;
        uint256[] memory nonces = classes[classId].nonceIds;
        // _lastBondNonces can be recovered from the last message of the nonceId
        // @drisky we can indeed
        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchActiveSupply += activeSupply(classId, nonces[i]);
        }
        return _batchActiveSupply;
    }

    function batchBurnedSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchBurnedSupply;
        uint256[] memory nonces = classes[classId].nonceIds;

        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchBurnedSupply += burnedSupply(classId, nonces[i]);
        }
        return _batchBurnedSupply;
    }

    function batchRedeemedSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchRedeemedSupply;
        uint256[] memory nonces = classes[classId].nonceIds;

        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchRedeemedSupply += redeemedSupply(classId, nonces[i]);
        }
        return _batchRedeemedSupply;
    }

    function batchTotalSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchTotalSupply;
        uint256[] memory nonces = classes[classId].nonceIds;

        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchTotalSupply += totalSupply(classId, nonces[i]);
        }
        return _batchTotalSupply;
    }

    function _transferFrom(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) private {
        require(from != address(0), "ERC3475: can't transfer from the zero address");
        require(to != address(0), "ERC3475: can't transfer to the zero address");
        require(classes[classId].nonces[nonceId].balances[from] >= amount, "ERC3475: not enough bond to transfer");
        _transfer(from, to, classId, nonceId, amount);
    }

    function _transfer(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) private {
        require(from != to, "ERC3475: can't transfer to the same address");
        classes[classId].nonces[nonceId].balances[from]-= amount;
        classes[classId].nonces[nonceId].balances[to] += amount;
    }

    function _issue(address to, uint256 classId, uint256 nonceId, uint256 amount) private {
        classes[classId].nonces[nonceId].balances[to] += amount;
        classes[classId].nonces[nonceId]._activeSupply += amount;
    }

    function _redeem(address from, uint256 classId, uint256 nonceId, uint256 amount) private {
        require(classes[classId].nonces[nonceId].balances[from] >= amount);
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId]._activeSupply -= amount;
        classes[classId].nonces[nonceId]._redeemedSupply += amount;
    }

    function _burn(address from, uint256 classId, uint256 nonceId, uint256 amount) private {
        require(classes[classId].nonces[nonceId].balances[from] >= amount);
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId]._activeSupply -= amount;
        classes[classId].nonces[nonceId]._burnedSupply += amount;
    }
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT



interface IERC3475 {

    // WRITE

    /**
     * @dev allows the transfer of a bond type from an address to another.
     * @param from argument is the address of the holder whose balance about to decrees.
     * @param to argument is the address of the recipient whose balance is about to increased.
     * @param classId is the classId of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonceId of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that will be transferred from "_from" address to "_to" address.
     */
    function transferFrom(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) external;


    /**
     * @dev  allows issuing any number of bond types to an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param to is the address to which the bond will be issued.
     * @param classId is the classId of the bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonceId of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that "to" address will receive.
     */
    function issue(address to, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
     * @dev  allows redemption of any number of bond types from an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param from is the address from which the bond will be redeemed.
     * @param classId is the class nonce of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonce of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that "from" address will redeem.
     */
    function redeem(address from, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
     * @dev  allows the transfer of any number of bond types from an address to another.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param from argument is the address of the holder whose balance about to decrees.
     * @param classId is the class nonce of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonce of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that will be transferred from "_from"address to "_to" address.
     */
    function burn(address from, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
     * @dev Allows spender to withdraw from your account multiple times, up to the amount.
     * @notice If this function is called again it overwrites the current allowance with amount.
     * @param spender is the address the caller approve for his bonds
     * @param classId is the classId nonce of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonceId of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond that the spender is approved for.
     */
    function approve(address spender, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
      * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
      * @dev MUST emit the ApprovalForAll event on success.
      * @param operator  Address to add to the set of authorized operators
      * @param classId is the classId nonce of bond, the first bond class created will be 0, and so on.
      * @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalFor(address operator, uint256 classId, bool approved) external;

    /**
     * @dev Allows spender to withdraw bonds from your account multiple times, up to the amount.
     * @notice If this function is called again it overwrites the current allowance with amount.
     * @param spender is the address the caller approve for his bonds.
     * @param classIds is the list of classIds of bond.
     * @param nonceIds is the list of nonceIds of the given bond class.
     * @param amounts is the list of amounts of the bond that the spender is approved for.
     */
    function batchApprove(address spender, uint256[] calldata classIds, uint256[] calldata nonceIds, uint256[] calldata amounts) external;


    // READ

    /**
     * @dev Returns the total supply of the bond in question
     */
    function totalSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the redeemed supply of the bond in question
     */
    function redeemedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the active supply of the bond in question
     */
    function activeSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the burned supply of the bond in question
     */
    function burnedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the balance of the giving bond classId and bond nonce
     */
    function balanceOf(address account, uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the symbol of the giving bond classId
     */
    function symbol(uint256 classId) external view returns (string memory);

    /**
     * @dev Returns the informations for the class of given classId
     * @notice Every bond contract can have their own list of class informations
     */
    function classInfos(uint256 classId) external view returns (uint256[] memory);

    /**
     * @dev Returns the information description for a given class info
     * @notice Every bond contract can have their own list of class informations
     */
    function classInfoDescription(uint256 classInfo) external view returns (string memory);

    /**
     * @dev Returns the information description for a given nonce info
     * @notice Every bond contract can have their own list of nonce informations
     */
    function nonceInfoDescription(uint256 nonceInfo) external view returns (string memory);

    /**
     * @dev Returns the informations for the nonce of given classId and nonceId
     * @notice Every bond contract can have their own list. But the first uint256 in the list MUST be the UTC time code of the issuing time.
     */
    function nonceInfos(uint256 classId, uint256 nonceId) external view returns (uint256[] memory);

    /**
     * @dev  allows anyone to check if a bond is redeemable.
     * @notice the conditions of redemption can be specified with one or several internal functions.
     */
    function isRedeemable(uint256 classId, uint256 nonceId) external view returns (bool);

    /**
     * @notice  Returns the amount which spender is still allowed to withdraw from owner.
     */
    function allowance(address owner, address spender, uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
    * @notice Queries the approval status of an operator for a given owner.
    * @return True if the operator is approved, false if not
    */
    function isApprovedFor(address owner, address operator, uint256 classId) external view returns (bool);

    /**
    * @notice MUST trigger when tokens are transferred, including zero value transfers.
    */
    event Transfer(address indexed _operator, address indexed _from, address indexed _to, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @notice MUST trigger when tokens are issued
    */
    event Issue(address indexed _operator, address indexed _to, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @notice MUST trigger when tokens are redeemed
    */
    event Redeem(address indexed _operator, address indexed _from, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @notice MUST trigger when tokens are burned
    */
    event Burn(address indexed _operator, address indexed _from, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @dev MUST emit when approval for a second party/operator address to manage all bonds from a classId given for an owner address is enabled or disabled (absence of an event assumes disabled).
    */
    event ApprovalFor(address indexed _owner, address indexed _operator, uint256 classId, bool _approved);

}

pragma solidity 0.8.13;


// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import "./IERC3475.sol";
import "./IData.sol";


interface IDebondBond is IERC3475 {

    function createNonce(uint256 classId, uint256 nonceId, uint256 maturityTime, uint256 liqT) external;

    function createClass(uint256 classId, string memory symbol, IData.InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) external;

    function classExists(uint256 classId) external returns (bool);

    function nonceExists(uint256 classId, uint256 nonceId) external returns (bool);

    function bondDetails(uint256 classId, uint256 nonceId) external view returns (string memory _symbol, IData.InterestRateType _interestRateType, address _tokenAddress, uint256 _periodTimestamp, uint256 _maturityDate, uint256 _issuanceDate);

    function isActive() external returns (bool);


}

pragma solidity 0.8.13;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface IData {

    enum InterestRateType {FixedRate, FloatingRate}

    function addClass(uint classId, string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp) external;

    function updateTokenAllowed(address tokenA, address tokenB, bool allowed) external;

    function isPairAllowed(address tokenA, address tokenB) external view returns (bool);

    function getClassFromId(uint classId) external view returns(string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp);

    function getLastNonceCreated(uint classId) external view returns(uint nonceId, uint createdAt);

    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external;
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