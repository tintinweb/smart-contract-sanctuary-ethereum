// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BBBBBBBGG&@@@@@@@@@&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P!:          :[email protected]@@@&P7^.        .^?G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&J.            :#@@@#7.                  :Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&!              [email protected]@@B:                        !&@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@P               [email protected]@@~                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@J               [email protected]@&.                              [email protected]@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@G               [email protected]@@.                                [email protected]@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.               &@@Y                                  #@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&               [email protected]@@&##########&&&&&&&&&&&#############@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&               [email protected]@@@@@@@@@@@@@#B######&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.               &@@@@@@@@@@@@@B~         .:!5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@B               [email protected]@@@@@@@@@@@@@@&!            .7#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@Y               [email protected]@@@@@@@@@@@@@@@B.             ^#@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@G               [email protected]@@@@@@@@@@@@@@@@:              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@?              [email protected]@@@@@@@@@@@@@@@@.              ^@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@5:            [email protected]@@@@@@@@@@@@@@B               [email protected]@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G7^.         :[email protected]@@@@@@@@@@@@@:               #@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#######BB&@@@@@@@@@@@@@7               [email protected]@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?               [email protected]@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.                                 ^@@@:               [email protected]@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@Y                                 [email protected]@#               ^@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@!                               [email protected]@@:              [email protected]@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@Y                             [email protected]@@^              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&~                         !&@@&.             :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&?.                   .J&@@@?             [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y~.           :!5&@@@#7          .^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGGGB#&@@@@@@@@BPGGGGGGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./common/SaleCommon.sol";

contract ETHSale is AccessControl, SaleCommon {
    struct Sale {
        uint256 id;
        uint256 volume;
        uint256 presale;
        uint256 starttime; // to start immediately, set starttime = 0
        uint256 endtime;
        bool active;
        bytes32 merkleRoot; // Merkle root of the entrylist Merkle tree, 0x00 for non-merkle sale
        uint256 maxQuantity;
        uint256 price; // in Wei, where 10^18 Wei = 1 ETH
        uint256 startTokenIndex;
        uint256 maxPLOTs;
        uint256 mintedPLOTs;
    }

    Sale[] public sales;
    mapping(uint256 => mapping(address => uint256)) public minted; // sale ID => account => quantity

    /// @notice Constructor
    /// @param _plot Storyverse Plot contract
    constructor(address _plot) SaleCommon(_plot) {}

    /// @notice Get the current sale
    /// @return Current sale
    function currentSale() public view returns (Sale memory) {
        require(sales.length > 0, "no current sale");
        return sales[sales.length - 1];
    }

    /// @notice Get the current sale ID
    /// @return Current sale ID
    function currentSaleId() public view returns (uint256) {
        require(sales.length > 0, "no current sale");
        return sales.length - 1;
    }

    /// @notice Checks if the provided token ID parameters are likely to overlap a previous or current sale
    /// @param _startTokenIndex Token index to start the sale from
    /// @param _maxPLOTs Maximum number of PLOTs that can be minted in this sale
    /// @return valid_ If the current token ID range paramters are likely safe
    function isSafeTokenIdRange(uint256 _startTokenIndex, uint256 _maxPLOTs)
        external
        view
        returns (bool valid_)
    {
        return _isSafeTokenIdRange(_startTokenIndex, _maxPLOTs, sales.length);
    }

    function _checkSafeTokenIdRange(
        uint256 _startTokenIndex,
        uint256 _maxPLOTs,
        uint256 _maxSaleId
    ) internal view {
        // If _maxSaleId is passed in as the current sale ID, then
        // the check will skip the current sale ID in _isSafeTokenIdRange()
        // since in that case _maxSaleId == sales.length - 1
        require(
            _isSafeTokenIdRange(_startTokenIndex, _maxPLOTs, _maxSaleId),
            "overlapping token ID range"
        );
    }

    function _isSafeTokenIdRange(
        uint256 _startTokenIndex,
        uint256 _maxPLOTs,
        uint256 _maxSaleId
    ) internal view returns (bool valid_) {
        if (_maxPLOTs == 0) {
            return true;
        }

        for (uint256 i = 0; i < _maxSaleId; i++) {
            // if no minted PLOTs in sale, ignore
            if (sales[i].mintedPLOTs == 0) {
                continue;
            }

            uint256 saleStartTokenIndex = sales[i].startTokenIndex;
            uint256 saleMintedPLOTs = sales[i].mintedPLOTs;

            if (_startTokenIndex < saleStartTokenIndex) {
                // start index is less than the sale's start token index, so ensure
                // it doesn't extend into the sale's range if max PLOTs are minted
                if (_startTokenIndex + _maxPLOTs - 1 >= saleStartTokenIndex) {
                    return false;
                }
            } else {
                // start index greater than or equal to the sale's start token index, so ensure
                // it starts after the sale's start token index + the number of PLOTs minted
                if (_startTokenIndex <= saleStartTokenIndex + saleMintedPLOTs - 1) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @notice Adds a new sale
    /// @param _volume Volume of the sale
    /// @param _presale Presale of the sale
    /// @param _starttime Start time of the sale
    /// @param _endtime End time of the sale
    /// @param _active Whether the sale is active
    /// @param _merkleRoot Merkle root of the entry list Merkle tree, 0x00 for non-merkle sale
    /// @param _maxQuantity Maximum number of PLOTs per account that can be sold
    /// @param _price Price of each PLOT
    /// @param _startTokenIndex Token index to start the sale from
    /// @param _maxPLOTs Maximum number of PLOTs that can be minted in this sale
    function addSale(
        uint256 _volume,
        uint256 _presale,
        uint256 _starttime,
        uint256 _endtime,
        bool _active,
        bytes32 _merkleRoot,
        uint256 _maxQuantity,
        uint256 _price,
        uint256 _startTokenIndex,
        uint256 _maxPLOTs
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = sales.length;

        checkTokenParameters(_volume, _presale, _startTokenIndex);

        _checkSafeTokenIdRange(_startTokenIndex, _maxPLOTs, saleId);

        Sale memory sale = Sale({
            id: saleId,
            volume: _volume,
            presale: _presale,
            starttime: _starttime,
            endtime: _endtime,
            active: _active,
            merkleRoot: _merkleRoot,
            maxQuantity: _maxQuantity,
            price: _price,
            startTokenIndex: _startTokenIndex,
            maxPLOTs: _maxPLOTs,
            mintedPLOTs: 0
        });

        sales.push(sale);

        emit SaleAdded(msg.sender, saleId);
    }

    /// @notice Updates the current sale
    /// @param _volume Volume of the sale
    /// @param _presale Presale of the sale
    /// @param _starttime Start time of the sale
    /// @param _endtime End time of the sale
    /// @param _active Whether the sale is active
    /// @param _merkleRoot Merkle root of the entry list Merkle tree, 0x00 for non-merkle sale
    /// @param _maxQuantity Maximum number of PLOTs per account that can be sold
    /// @param _price Price of each PLOT
    /// @param _startTokenIndex Token index to start the sale from
    /// @param _maxPLOTs Maximum number of PLOTs that can be minted in this sale
    function updateSale(
        uint256 _volume,
        uint256 _presale,
        uint256 _starttime,
        uint256 _endtime,
        bool _active,
        bytes32 _merkleRoot,
        uint256 _maxQuantity,
        uint256 _price,
        uint256 _startTokenIndex,
        uint256 _maxPLOTs
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();

        checkTokenParameters(_volume, _presale, _startTokenIndex);
        _checkSafeTokenIdRange(_startTokenIndex, _maxPLOTs, saleId);

        Sale memory sale = Sale({
            id: saleId,
            volume: _volume,
            presale: _presale,
            starttime: _starttime,
            endtime: _endtime,
            active: _active,
            merkleRoot: _merkleRoot,
            maxQuantity: _maxQuantity,
            price: _price,
            startTokenIndex: _startTokenIndex,
            maxPLOTs: _maxPLOTs,
            mintedPLOTs: sales[saleId].mintedPLOTs
        });

        sales[saleId] = sale;

        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the volume of the current sale
    /// @param _volume Volume of the sale
    function updateSaleVolume(uint256 _volume) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();

        checkTokenParameters(_volume, sales[saleId].presale, sales[saleId].startTokenIndex);

        sales[saleId].volume = _volume;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the presale of the current sale
    /// @param _presale Presale of the sale
    function updateSalePresale(uint256 _presale) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();

        checkTokenParameters(sales[saleId].volume, _presale, sales[saleId].startTokenIndex);

        sales[saleId].presale = _presale;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the start time of the current sale
    /// @param _starttime Start time of the sale
    function updateSaleStarttime(uint256 _starttime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].starttime = _starttime;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the end time of the current sale
    /// @param _endtime End time of the sale
    function updateSaleEndtime(uint256 _endtime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].endtime = _endtime;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the active status of the current sale
    /// @param _active Whether the sale is active
    function updateSaleActive(bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].active = _active;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the merkle root of the current sale
    /// @param _merkleRoot Merkle root of the entry list Merkle tree, 0x00 for non-merkle sale
    function updateSaleMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].merkleRoot = _merkleRoot;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the max quantity of the current sale
    /// @param _maxQuantity Maximum number of PLOTs per account that can be sold
    function updateSaleMaxQuantity(uint256 _maxQuantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].maxQuantity = _maxQuantity;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the price of each PLOT for the current sale
    /// @param _price Price of each PLOT
    function updateSalePrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].price = _price;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the start token index of the current sale
    /// @param _startTokenIndex Token index to start the sale from
    function updateSaleStartTokenIndex(uint256 _startTokenIndex)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 saleId = currentSaleId();

        _checkSafeTokenIdRange(_startTokenIndex, sales[saleId].maxPLOTs, saleId);
        checkTokenParameters(sales[saleId].volume, sales[saleId].presale, _startTokenIndex);

        sales[saleId].startTokenIndex = _startTokenIndex;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the  of the current sale
    /// @param _maxPLOTs Maximum number of PLOTs that can be minted in this sale
    function updateSaleMaxPLOTs(uint256 _maxPLOTs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();

        _checkSafeTokenIdRange(sales[saleId].startTokenIndex, _maxPLOTs, saleId);

        sales[saleId].maxPLOTs = _maxPLOTs;
        emit SaleUpdated(msg.sender, saleId);
    }

    function _mintTo(
        address _to,
        uint256 _volume,
        uint256 _presale,
        uint256 _startTokenIndex,
        uint256 _quantity
    ) internal {
        require(_quantity > 0, "quantity must be greater than 0");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenIndex = _startTokenIndex + i;
            uint256 tokenId = buildTokenId(_volume, _presale, tokenIndex);

            IStoryversePlot(plot).safeMint(_to, tokenId);
        }

        emit Minted(msg.sender, _to, _quantity, msg.value);
    }

    /// @notice Mints new tokens in exchange for ETH
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function mintTo(address _to, uint256 _quantity) external payable nonReentrant {
        Sale memory sale = currentSale();

        // only proceed if no merkle root is set
        require(sale.merkleRoot == bytes32(0), "merkle sale requires valid proof");

        // check sale validity
        require(sale.active, "sale is inactive");
        require(block.timestamp >= sale.starttime, "sale has not started");
        require(block.timestamp < sale.endtime, "sale has ended");

        // validate payment and authorized quantity
        require(msg.value == sale.price * _quantity, "incorrect payment for quantity and price");
        require(
            minted[sale.id][msg.sender] + _quantity <= sale.maxQuantity,
            "exceeds allowed quantity"
        );

        // check sale supply
        require(sale.mintedPLOTs + _quantity <= sale.maxPLOTs, "insufficient supply");

        sales[sale.id].mintedPLOTs += _quantity;
        minted[sale.id][msg.sender] += _quantity;

        _mintTo(
            _to,
            sale.volume,
            sale.presale,
            sale.startTokenIndex + sale.mintedPLOTs,
            _quantity
        );
    }

    /// @notice Mints new tokens in exchange for ETH based on the sale's entry list
    /// @param _proof Merkle proof to validate the caller is on the sale's entry list
    /// @param _maxQuantity Max quantity that the caller can mint
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function entryListMintTo(
        bytes32[] calldata _proof,
        uint256 _maxQuantity,
        address _to,
        uint256 _quantity
    ) external payable nonReentrant {
        Sale memory sale = currentSale();

        // validate merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxQuantity));
        require(MerkleProof.verify(_proof, sale.merkleRoot, leaf), "invalid proof");

        // check sale validity
        require(sale.active, "sale is inactive");
        require(block.timestamp >= sale.starttime, "sale has not started");
        require(block.timestamp < sale.endtime, "sale has ended");

        // validate payment and authorized quantity
        require(msg.value == sale.price * _quantity, "incorrect payment for quantity and price");
        require(
            minted[sale.id][msg.sender] + _quantity <= Math.max(sale.maxQuantity, _maxQuantity),
            "exceeds allowed quantity"
        );

        // check sale supply
        require(sale.mintedPLOTs + _quantity <= sale.maxPLOTs, "insufficient supply");

        sales[sale.id].mintedPLOTs += _quantity;
        minted[sale.id][msg.sender] += _quantity;

        _mintTo(
            _to,
            sale.volume,
            sale.presale,
            sale.startTokenIndex + sale.mintedPLOTs,
            _quantity
        );
    }

    /// @notice Administrative mint function within the constraints of the current sale, skipping some checks
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function adminSaleMintTo(address _to, uint256 _quantity) external onlyRole(MINTER_ROLE) {
        Sale memory sale = currentSale();

        // check sale supply
        require(sale.mintedPLOTs + _quantity <= sale.maxPLOTs, "insufficient supply");

        sales[sale.id].mintedPLOTs += _quantity;
        minted[sale.id][msg.sender] += _quantity;

        _mintTo(
            _to,
            sale.volume,
            sale.presale,
            sale.startTokenIndex + sale.mintedPLOTs,
            _quantity
        );
    }

    /// @notice Administrative mint function
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function adminMintTo(
        address _to,
        uint256 _volume,
        uint256 _presale,
        uint256 _startTokenIndex,
        uint256 _quantity
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // add a sale (clobbering any current sale) to ensure token ranges
        // are respected and recorded
        addSale(
            _volume,
            _presale,
            block.timestamp,
            block.timestamp,
            false,
            bytes32(0),
            0,
            2**256 - 1,
            _startTokenIndex,
            _quantity
        );

        // record the sale as fully minted
        sales[sales.length - 1].mintedPLOTs = _quantity;

        _mintTo(_to, _volume, _presale, _startTokenIndex, _quantity);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IStoryversePlot.sol";

contract SaleCommon is AccessControl, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public plot;

    /// @notice Emitted when a new sale is added to the contract
    /// @param who Admin that created the sale
    /// @param saleId Sale ID, will be the current sale
    event SaleAdded(address who, uint256 saleId);

    /// @notice Emitted when the current sale is updated
    /// @param who Admin that updated the sale
    /// @param saleId Sale ID, will be the current sale
    event SaleUpdated(address who, uint256 saleId);

    /// @notice Emitted when new tokens are sold and minted
    /// @param who Purchaser (payer) for the tokens
    /// @param to Owner of the newly minted tokens
    /// @param quantity Quantity of tokens minted
    /// @param amount Amount paid in Wei
    event Minted(address who, address to, uint256 quantity, uint256 amount);

    /// @notice Emitted when funds are withdrawn from the contract
    /// @param to Recipient of the funds
    /// @param amount Amount sent in Wei
    event FundsWithdrawn(address to, uint256 amount);

    /// @notice Constructor
    /// @param _plot Storyverse Plot contract
    constructor(address _plot) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        plot = _plot;
    }

    function checkTokenParameters(
        uint256 _volume,
        uint256 _presale,
        uint256 _tokenIndex
    ) internal pure {
        require(_volume > 0 && _volume < 2**10, "invalid volume");
        require(_presale < 2**2, "invalid presale");
        require(_tokenIndex < 2**32, "invalid token index");
    }

    function buildTokenId(
        uint256 _volume,
        uint256 _presale,
        uint256 _tokenIndex
    ) public view returns (uint256 tokenId_) {
        checkTokenParameters(_volume, _presale, _tokenIndex);

        uint256 superSecretSpice = uint256(
            keccak256(
                abi.encodePacked(
                    (0x4574c8c75d6e88acd28f7e467dac97b5c60c3838d9dad993900bdf402152228e ^
                        uint256(blockhash(block.number - 1))) + _tokenIndex
                )
            )
        ) & 0xffffffff;

        tokenId_ = (_volume << 245) | (_presale << 243) | (superSecretSpice << 211) | _tokenIndex;

        return tokenId_;
    }

    /// @notice Decode a token ID into its component parts
    /// @param _tokenId Token ID
    /// @return volume_ Volume of the sale
    /// @return presale_ Presale of the sale
    /// @return superSecretSpice_ Super secret spice
    /// @return tokenIndex_ Token index
    function decodeTokenId(uint256 _tokenId)
        external
        pure
        returns (
            uint256 volume_,
            uint256 presale_,
            uint256 superSecretSpice_,
            uint256 tokenIndex_
        )
    {
        volume_ = (_tokenId >> 245) & 0x3ff;
        presale_ = (_tokenId >> 243) & 0x3;
        superSecretSpice_ = (_tokenId >> 211) & 0xffffffff;
        tokenIndex_ = _tokenId & 0xffffffff;

        return (volume_, presale_, superSecretSpice_, tokenIndex_);
    }

    /// @notice Withdraw funds from the contract
    /// @param _to Recipient of the funds
    /// @param _amount Amount sent, in Wei
    function withdrawFunds(address payable _to, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_amount <= address(this).balance, "not enough funds");
        _to.transfer(_amount);
        emit FundsWithdrawn(_to, _amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ~0.8.13;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@imtbl/imx-contracts/contracts/IMintable.sol";
import "./IExtensionManager.sol";

interface IStoryversePlot is
    IERC2981Upgradeable,
    IERC721MetadataUpgradeable,
    IAccessControlUpgradeable,
    IMintable
{
    /// @notice Emitted when a new extension manager is set
    /// @param who Admin that set the extension manager
    /// @param extensionManager New extension manager contract
    event ExtensionManagerSet(address indexed who, address indexed extensionManager);

    /// @notice Emitted when a new Immutable X is set
    /// @param who Admin that set the extension manager
    /// @param imx New Immutable X address
    event IMXSet(address indexed who, address indexed imx);

    /// @notice Emitted when a new token is minted and a blueprint is set
    /// @param to Owner of the newly minted token
    /// @param tokenId Token ID that was minted
    /// @param blueprint Blueprint extracted from the blob
    event AssetMinted(address to, uint256 tokenId, bytes blueprint);

    /// @notice Emitted when the new base URI is set
    /// @param who Admin that set the base URI
    event BaseURISet(address indexed who);

    /// @notice Emitted when funds are withdrawn from the contract
    /// @param to Recipient of the funds
    /// @param amount Amount sent in Wei
    event FundsWithdrawn(address to, uint256 amount);

    /// @notice Get the base URI
    /// @return uri_ Base URI
    function baseURI() external returns (string memory uri_);

    /// @notice Get the extension manager
    /// @return extensionManager_ Extension manager
    function extensionManager() external returns (IExtensionManager extensionManager_);

    /// @notice Get the Immutable X address
    /// @return imx_ Immutable X address
    function imx() external returns (address imx_);

    /// @notice Get the blueprint for a token ID
    /// @param _tokenId Token ID
    /// @return blueprint_ Blueprint
    function blueprints(uint256 _tokenId) external returns (bytes memory blueprint_);

    /// @notice Sets a new extension manager
    /// @param _extensionManager New extension manager
    function setExtensionManager(address _extensionManager) external;

    /// @notice Mint a new token
    /// @param _to Owner of the newly minted token
    /// @param _tokenId Token ID
    function safeMint(address _to, uint256 _tokenId) external;

    /// @notice Sets a base URI
    /// @param _uri Base URI
    function setBaseURI(string calldata _uri) external;

    /// @notice Get PLOT data for the token ID
    /// @param _tokenId Token ID
    /// @param _in Input data
    /// @return out_ Output data
    function getPLOTData(uint256 _tokenId, bytes memory _in) external returns (bytes memory out_);

    /// @notice Sets PLOT data for the token ID
    /// @param _tokenId Token ID
    /// @param _in Input data
    /// @return out_ Output data
    function setPLOTData(uint256 _tokenId, bytes memory _in) external returns (bytes memory out_);

    /// @notice Pays for PLOT data of the token ID
    /// @param _tokenId Token ID
    /// @param _in Input data
    /// @return out_ Output data
    function payPLOTData(uint256 _tokenId, bytes memory _in)
        external
        payable
        returns (bytes memory out_);

    /// @notice Get data
    /// @param _in Input data
    /// @return out_ Output data
    function getData(bytes memory _in) external returns (bytes memory out_);

    /// @notice Sets data
    /// @param _in Input data
    /// @return out_ Output data
    function setData(bytes memory _in) external returns (bytes memory out_);

    /// @notice Pays for data
    /// @param _in Input data
    /// @return out_ Output data
    function payData(bytes memory _in) external payable returns (bytes memory out_);

    /// @notice Transfers the ownership of the contract
    /// @param newOwner New owner of the contract
    function transferOwnership(address newOwner) external;

    /// @notice Sets the Immutable X address
    /// @param _imx New Immutable X
    function setIMX(address _imx) external;

    /// @notice Withdraw funds from the contract
    /// @param _to Recipient of the funds
    /// @param _amount Amount sent, in Wei
    function withdrawFunds(address payable _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
pragma solidity ^0.8.4;

interface IMintable {
    function mintFor(
        address to,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ~0.8.13;

interface IExtensionManager {
    function beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function beforeTokenApprove(address _to, uint256 _tokenId) external;

    function afterTokenApprove(address _to, uint256 _tokenId) external;

    function beforeApproveAll(address _operator, bool _approved) external;

    function afterApproveAll(address _operator, bool _approved) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory uri_);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address royaltyReceiver_, uint256 royaltyAmount_);

    function getPLOTData(uint256 _tokenId, bytes memory _in)
        external
        view
        returns (bytes memory out_);

    function setPLOTData(uint256 _tokenId, bytes memory _in) external returns (bytes memory out_);

    function payPLOTData(uint256 _tokenId, bytes memory _in)
        external
        payable
        returns (bytes memory out_);

    function getData(bytes memory _in) external view returns (bytes memory out_);

    function setData(bytes memory _in) external returns (bytes memory out_);

    function payData(bytes memory _in) external payable returns (bytes memory out_);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}