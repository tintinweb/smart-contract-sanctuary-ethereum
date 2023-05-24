// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title BloodDonation
 * @dev Implements a decentralized application for blood donation campaigns and blood pouch management.
 */
contract BloodDonation is ERC20 {
    enum BloodGroup { 
        A_positive,
        A_negative,
        B_positive,
        B_negative,
        AB_positive,
        AB_negative,
        O_positive,
        O_negative
    }

    enum BloodStatus {
        Available,
        Expired,
        Received
    }

    struct Campaign {
        uint256 id;
        address owner;
        string title;
        string description;
        string imageId;
        string videoId;
        uint256 targetAmount;
        uint256 collectedAmount;
        uint256 creationDate;
        uint256 deadlineDate;
        address[] donators;
        uint256[] donations;
    }

    struct BloodPouch {
        uint256 pouchID;
        BloodGroup bloodGroup;
        address donorID;
        address organizationID;
        address receiverID;
        string details;
        uint256 publishDate;
        uint256 receivedDate;
        BloodStatus status;
    }

    mapping(uint256 => Campaign) private _campaigns;
    mapping(uint256 => BloodPouch) private _pouches;
    uint256 private _campaignCount;
    uint256 private _pouchCount;
    address private _isAdmin;
    mapping(address => bool) private _isOrganization;

    /**
     * @dev Modifier to only allow organization access
     */
    modifier onlyOrganization() {
        require(_isOrganization[msg.sender], "Caller is not an organization");
        _;
    }

    /**
     * @dev Constructor function
     */
    constructor() ERC20("SOCIAL TOKEN", "SOCIAL") {
        _isAdmin = msg.sender;
        _isOrganization[msg.sender] = true;
    }

    /**
     * @dev Function to check if an address is an organization
     * @param _account The address to check
     * @return A boolean indicating if the address is an organization
     */
    function isOrganization(address _account) public view returns (bool) {
        return _isOrganization[_account];
    }

    /**
     * @dev Function to check if an address is an admin
     * @param _account The address to check
     * @return A boolean indicating if the address is an admin
     */
    function isAdmin(address _account) public view returns (bool) {
        return _account == _isAdmin;
    }

    /**
     * @dev Function to add a new organization
     * @param _adminAddress The address of an admin
     */
    function addOrganization(address _adminAddress) public {
        require(msg.sender == _isAdmin, "Only admin can add organization");
        _isOrganization[_adminAddress] = true;
    }

    /**
    * @dev Function to enter new blood details
    * @param _donorID The address of the donor
    * @param _bloodGroup The blood group
    * @param _details Additional details about the blood pouch
    * @return The generated pouch ID
    */
    function enterBloodDetails(
        address _donorID,
        BloodGroup _bloodGroup,
        string memory _details
    ) public onlyOrganization returns (uint256) {
        uint256 pouchID = _pouchCount;

        BloodPouch memory newPouch = BloodPouch({
            pouchID: pouchID,
            donorID: _donorID,
            bloodGroup: _bloodGroup,
            receiverID: address(0),
            organizationID: msg.sender,
            details: _details,
            publishDate: block.timestamp,
            receivedDate: 0,
            status: BloodStatus.Available
        });

        _pouches[pouchID] = newPouch;
        _pouchCount++;

        // Mint governance tokens to the donor
        _mint(_donorID, 100 * 10 ** decimals());

        return pouchID;
    }

    /**
    * @dev Function to get all available blood pouches
    * @return An array of available blood pouches
    */
    function getAllAvailablePouches() public view returns (BloodPouch[] memory) {
        uint256 count = 0;

        // Count the number of available pouches
        for (uint256 i = 0; i < _pouchCount; i++) {
            if (_pouches[i].status == BloodStatus.Available) {
                count++;
            }
        }

        // Create an array to store the available pouches
        BloodPouch[] memory availablePouches = new BloodPouch[](count);
        uint256 index = 0;

        // Iterate through the pouches and add the available ones to the array
        for (uint256 i = 0; i < _pouchCount; i++) {
            if (_pouches[i].status == BloodStatus.Available) {
                availablePouches[index] = _pouches[i];
                index++;
            }
        }

        return availablePouches;
    }

    /**
     * @dev Function to get the list of blood pouches received by the caller
     * @param _receiver The address of the receiver
     * @return An array of blood pouches received by the address
     */
    function getReceivedPouches(address _receiver) public view returns (BloodPouch[] memory) {
        BloodPouch[] memory receivedPouches = new BloodPouch[](_pouchCount);
        uint256 count = 0;

        for (uint256 i = 0; i < _pouchCount; i++) {
            if (_pouches[i].receiverID == _receiver) {
                receivedPouches[count] = _pouches[i];
                count++;
            }
        }

        BloodPouch[] memory result = new BloodPouch[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = receivedPouches[i];
        }

        return result;
    }

    /**
    * @dev Function to get the blood pouches owned by a specific address
    * @param _owner The address of the owner
    * @return An array of blood pouches owned by the address
    */
    function getMyPouches(address _owner) public view returns (BloodPouch[] memory) {
        uint256 count = 0;

        // Count the number of pouches owned by the address
        for (uint256 i = 0; i < _pouchCount; i++) {
            if (_pouches[i].donorID == _owner) {
                count++;
            }
        }

        // Create an array to store the pouches owned by the address
        BloodPouch[] memory myPouches = new BloodPouch[](count);
        uint256 index = 0;

        // Iterate through the pouches and add the ones owned by the address to the array
        for (uint256 i = 0; i < _pouchCount; i++) {
            if (_pouches[i].donorID == _owner) {
                myPouches[index] = _pouches[i];
                index++;
            }
        }

        return myPouches;
    }

    /**
     * @dev Function to assign a receiver to a blood pouch
     * @param _pouchID The ID of the blood pouch
     */
    function assignReceiver(uint256 _pouchID) public payable {
        require(_pouches[_pouchID].donorID != address(0), "Pouch ID does not exist");
        require(_pouches[_pouchID].receiverID == address(0), "Pouch already has a receiver");

        // Transfer the received Ether to the receiver's address
        payable(_pouches[_pouchID].receiverID).transfer(msg.value);

        _pouches[_pouchID].receiverID = msg.sender;
        _pouches[_pouchID].status = BloodStatus.Received;
    }

    /**
     * @dev Function to create a new campaign
     * @param _owner The address of the campaign owner
     * @param _title The title of the campaign
     * @param _description The description of the campaign
     * @param _imageId The ID of the campaign's image
     * @param _videoId The ID of the campaign's video
     * @param _targetAmount The target amount of the campaign
     * @param _deadlineDate The deadline date of the campaign
     * @return The ID of the created campaign
     */
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        string memory _imageId,
        string memory _videoId,
        uint256 _targetAmount,
        uint256 _deadlineDate
    ) public onlyOrganization returns (uint256) {
        uint256 id = _campaignCount;

        Campaign memory newCampaign = Campaign({
            id: id,
            owner: _owner,
            title: _title,
            description: _description,
            imageId: _imageId,
            videoId: _videoId,
            targetAmount: _targetAmount,
            collectedAmount: 0,
            creationDate: block.timestamp,
            deadlineDate: _deadlineDate,
            donators: new address[](0),
            donations: new uint256[](0)
        });

        _campaigns[id] = newCampaign;
        _campaignCount++;

        return id;
    }

    /**
     * @dev Function to donate to a campaign
     * @param _id The ID of the campaign
     */
    function donateToCampaign(uint256 _id) public payable {
        require(_campaigns[_id].owner != address(0), "The specified campaign ID does not exist");

        // Transfer the received Ether to the campaign owner's address
        payable(_campaigns[_id].owner).transfer(msg.value);

        // Mint governance tokens to the donor
        _mint(msg.sender, msg.value);

        // Add the donation to the campaign
        _campaigns[_id].donators.push(msg.sender);
        _campaigns[_id].donations.push(msg.value);
        _campaigns[_id].collectedAmount += msg.value;
    }

    /**
    * @dev Function to get all active campaign details
    * @return An array of active campaign details
    */
    function getAllActiveCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory activeCampaigns = new Campaign[](_campaignCount);
        uint256 activeCampaignCount = 0;

        for (uint256 i = 0; i < _campaignCount; i++) {
            Campaign memory campaign = _campaigns[i];
            if (campaign.deadlineDate > block.timestamp) {
                activeCampaigns[activeCampaignCount] = campaign;
                activeCampaignCount++;
            }
        }

        Campaign[] memory result = new Campaign[](activeCampaignCount);
        for (uint256 i = 0; i < activeCampaignCount; i++) {
            result[i] = activeCampaigns[i];
        }

        return result;
    }

    /**
    * @dev Function to get all campaigns created by the caller (organization)
    * @return An array of campaigns
    */
    function getMyCampaigns() public view onlyOrganization returns (Campaign[] memory) {
        Campaign[] memory activeCampaigns = new Campaign[](_campaignCount);
        uint256 activeCampaignCount = 0;

        for (uint256 i = 0; i < _campaignCount; i++) {
            Campaign memory campaign = _campaigns[i];
            if (campaign.owner == msg.sender) {
                activeCampaigns[activeCampaignCount] = campaign;
                activeCampaignCount++;
            }
        }

        Campaign[] memory result = new Campaign[](activeCampaignCount);
        for (uint256 i = 0; i < activeCampaignCount; i++) {
            result[i] = activeCampaigns[i];
        }

        return result;
    }

    /**
     * @dev Function to get campaign details by ID
     * @param _id The ID of the campaign
     * @return id The unique identifier of the campaign
     * @return owner The owner of the campaign
     * @return title The title of the campaign
     * @return description The description of the campaign
     * @return imageId The imageId of the campaign
     * @return videoId The videoId of the campaign
     * @return targetAmount The targetAmount of the campaign
     * @return collectedAmount The amount collected by the campaign
     * @return creationDate The creation date of the campaign
     * @return deadlineDate The deadline date of the campaign
     * @return donators The donators of the campaign
     * @return donations The donations of the campaign
     * @dev Reverts if the specified campaign ID does not exist
    */
    function getCampaign(uint256 _id) public view returns (
        uint256 id,
        address owner,
        string memory title,
        string memory description,
        string memory imageId,
        string memory videoId,
        uint256 targetAmount,
        uint256 collectedAmount,
        uint256 creationDate,
        uint256 deadlineDate,
        address[] memory donators,
        uint256[] memory donations
    ) {
        require(_campaigns[_id].owner != address(0), "The specified campaign ID does not exist");

        Campaign memory campaign = _campaigns[_id];

        return (
            campaign.id,
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.imageId,
            campaign.videoId,
            campaign.targetAmount,
            campaign.collectedAmount,
            campaign.creationDate,
            campaign.deadlineDate,
            campaign.donators,
            campaign.donations
        );
    }

    /**
     * @dev Function to get the list of donators for a campaign donation
     * @param _id The ID of the campaign
     * @return donators An array of donators' addresses
     * @return donations An array of corresponding donation amounts
     * @dev Reverts if the specified campaign ID does not exist
    */
    function getCampaignDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        require(_campaigns[_id].owner != address(0), "The specified campaign ID does not exist");

        Campaign memory campaign = _campaigns[_id];

        return (campaign.donators, campaign.donations);
    }
}