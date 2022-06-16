/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

//SPDX-License-Identifier:NOLICENSE
pragma solidity 0.8.14;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
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

interface IERC20Metadata {
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IERC20 is IERC20Metadata {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

contract Escrow is Ownable {
    using SafeERC20 for IERC20;
    
    struct EscrowInfo {
        uint totalBlings;
        uint issuance;
        uint8 cliff;
    }

    struct WalletInfo {
        uint allocated;
        uint issued;
        uint lastClaimBlock;
        uint index;
        bool isActive;
    }

    address[] founders;
    address[] wallets;
    address public launchPad;
    address public bling;
    uint public startBlock;
    uint public blockInMnth;
    bool initializer;

    EscrowInfo public launchpadInfo;
    EscrowInfo public foundersInfo;
    EscrowInfo public walletsInfo;

    mapping(address => WalletInfo) public founderInfo;
    mapping(address => WalletInfo) public walletInfo;

    event Claim(
        address indexed account,
        uint issued,
        string indexed claimType
    );

    /**
    * @dev initialize the setting.
    */
    function initialize(
        address blingToken, //bling token address
        uint launchpadAllocation, //launch pad lockup token amount
        uint blockNo, //start block number - cliff starts from this block number
        uint8 launchPadCliff, //launch pad cliff
        uint8 founderCliff, //founder cliff
        uint8 walletsCliff, // wallet cliff
        uint issuanceOf //founder montly release - 2500 equals to 25%
    ) external onlyOwner {
        require(!initializer, "Escrow:: initialize: already initialized");
        require(blingToken != address(0), "Escrow:: initialize: bling != 0");
        require(launchpadAllocation != 0, "Escrow:: initialize: launchpad allocation != 0");
        require(blockNo > block.number, "Escrow:: initialize: should higher than current block");
        require(launchPadCliff != 0, "Escrow:: initialize: launchpad cliff != 0");
        require(founderCliff != 0, "Escrow:: initialize: escrow cliff != 0");
        require(walletsCliff != 0, "Escrow:: initialize: wallet cliff != 0");
        require(issuanceOf != 0, "Escrow:: initialize: issuanceOf != 0");

        initializer = true;
        bling = blingToken;
        startBlock = blockNo;
        blockInMnth = 30 days / 15;

        launchpadInfo = EscrowInfo({
            totalBlings : launchpadAllocation*(10**IERC20Metadata(bling).decimals()),
            issuance : 0,
            cliff : launchPadCliff
        });

        foundersInfo.cliff = founderCliff;
        foundersInfo.issuance = issuanceOf;

        walletsInfo.cliff = walletsCliff;
    }
    /**
    * @dev setting bling address.
    */
    function setbling(address blingToken) external onlyOwner {
        require(blingToken != address(0),"Escrow:: setbling: bling != 0");
        bling = blingToken;
    }

    /**
    * @dev setting start block.
    */
    function setStartBlock(uint blockNumber) external onlyOwner {
        require(startBlock < block.number,"Escrow:: setStartBlock: start block should lesser than block");
        require(blockNumber > 0,"Escrow:: setStartBlock: block number should higher than block");        
        startBlock = blockNumber;
    }

    /**
    * @dev setting escrow cliff.
    */
    function setFounderCliff(uint8 cliff) external onlyOwner {
        require((startBlock > 0) && (startBlock > block.number),"Escrow:: setFounderCliff: block has started");
        require(cliff > 0,"Escrow:: setFounderCliff: cliff should higher than zero");
        foundersInfo.cliff = cliff;
    }

    /**
    * @dev setting launch pad cliff.
    */
    function setLaunchPadCliff(uint8 cliff) external onlyOwner {
        require((startBlock > 0) && (startBlock > block.number),"Escrow:: setLaunchPadCliff: block has started");
        require(cliff > 0,"Escrow:: setLaunchPadCliff: cliff should higher than zero");
        launchpadInfo.cliff = cliff;
    }

    /**
    * @dev setting wallets cliff.
    */
    function setWalletsCliff(uint8 cliff) external onlyOwner {
        require((startBlock > 0) && (startBlock > block.number),"Escrow:: setWalletsCliff: block has started");
        require(cliff > 0,"Escrow:: setWalletsCliff: cliff should higher than zero");
        walletsInfo.cliff = cliff;
    }

    /**
    * @dev setting launch pad address.
    */
    function setLaunchPad(address launchpad) external onlyOwner {
        require((startBlock > 0) && (startBlock > block.number),"Escrow:: setLaunchPad: block has started");
        launchPad = launchpad;
    }

    /**
    * @dev adding founder to the founders list and setting allocation to the founder.
    */
    function addFounder(address[] calldata accounts, uint[] calldata allocations) external onlyOwner {
        require((startBlock > 0) && (startBlock > block.number),"Escrow:: addFounder: block hasn't started");
        require(accounts.length > 0, "Escrow:: addFounder: accounts length should be higher than zero");
        require(accounts.length == allocations.length, "Escrow:: addFounder: accounts and allocations length should be same");

        for(uint i=0;i<accounts.length;i++) {
            require(accounts[i] != address(0),"Escrow:: addFounder: account != 0");

            if(!founderInfo[accounts[i]].isActive) {
                founderInfo[accounts[i]].isActive = true;
                founderInfo[accounts[i]].index = founders.length;
                founders.push(accounts[i]);
            }

            founderInfo[accounts[i]].allocated += allocations[i];
            foundersInfo.totalBlings += allocations[i];
        }
    }

    /**
    * @dev remove founder from the list.
    */
    function removeFounder(address[] calldata accounts) external onlyOwner {
        require(accounts.length > 0, "Escrow:: removeFounder: account length > 0");

        for(uint i=0;i<accounts.length;i++) {
            if(founderInfo[accounts[i]].isActive) {
                founderInfo[accounts[i]].isActive = false;
                foundersInfo.totalBlings -= founderInfo[accounts[i]].allocated;
                founderInfo[accounts[i]].allocated = 0;
                //remove founder
                address last = founders[founders.length-1];
                founders[founderInfo[accounts[i]].index] = last;
                founders.pop();
            }
        }
    }

    /**
    * @dev adding wallet to the wallet list and setting allocation to the accounts.
    */
    function addWallets(address[] calldata accounts, uint[] calldata allocations) external onlyOwner {
        require((startBlock > 0) && (startBlock > block.number),"Escrow:: addWallets: block hasn't started");
        require(accounts.length > 0, "Escrow:: addWallets: accounts length should be higher than zero");
        require(accounts.length == allocations.length, "Escrow:: addWallets: accounts and allocations length should be same");

        for(uint i=0;i<accounts.length;i++) {
            require(accounts[i] != address(0),"Escrow:: addWallets: account != 0");

            if(!walletInfo[accounts[i]].isActive) {
                walletInfo[accounts[i]].isActive = true;
                walletInfo[accounts[i]].index = wallets.length;
                wallets.push(accounts[i]);
            }

            walletInfo[accounts[i]].allocated += allocations[i];
            walletsInfo.totalBlings += allocations[i];
        }
    }

    /**
    * @dev remove wallet from the list.
    */
    function removeWallet(address[] calldata accounts) external onlyOwner {
        require(accounts.length > 0, "Escrow:: removeFounder: account length > 0");

        for(uint i=0;i<accounts.length;i++) {
            if(walletInfo[accounts[i]].isActive) {
                walletInfo[accounts[i]].isActive = false;
                walletsInfo.totalBlings -= walletInfo[accounts[i]].allocated;
                walletInfo[accounts[i]].allocated = 0;
                //remove wallet
                address last = wallets[wallets.length-1];
                wallets[walletInfo[accounts[i]].index] = last;
                wallets.pop();
            }
        }
    }

    /**
    * @dev to claim founder and launch pad tokens.
    */
    function claim() external {
        require(startBlock < block.number,"Escrow:: claim: block hasn't started");
        address account = _msgSender();
        if(account == launchPad) {
            _launchPad(launchPad);
        } else if(founderInfo[account].isActive) {
            _founder(account);
        } else if(walletInfo[account].isActive) {
            _wallets(account);
        } else {
            revert("invalid account");
        }
    }

    function failsafe( address _token, address _to, uint amount) public onlyOwner {
        address _contractAdd = address(this);
        if(_token == address(0)){
            require(_contractAdd.balance >= amount,"insufficient bnb");
            payable(_to).transfer(amount);
        }
        else{
            require( IERC20(_token).balanceOf(_contractAdd) >= amount,"insufficient Token balance");
            IERC20(_token).transfer(_to, amount);
        }
    }

    /**
    * @dev show all the founder addresses.
    */
    function showFounders() public view returns (address[] memory) {
        return founders;
    }

    /**
    * @dev show all the wallet addresses.
    */
    function showWallets() public view returns (address[] memory) {
        return wallets;
    }

    /**
    * @dev show pending token for the given founder address.
    */
    function pendingClaim(address account) public view returns (uint claimable, uint lastClaim) {
        WalletInfo memory founder = founderInfo[account];

        if(founder.lastClaimBlock == 0) {            
            founder.lastClaimBlock = _cliff(foundersInfo.cliff);
        }

        if((!founder.isActive) ||
         (founder.issued >= founder.allocated) ||
         (founder.lastClaimBlock + blockInMnth > block.number) ) {
            return (0,0);
        }

        uint currBlock = block.number;
        uint pendingBlocks = (currBlock - founder.lastClaimBlock) / blockInMnth;
        uint blockClaimable = ((founder.allocated * foundersInfo.issuance) / 10000) * pendingBlocks;        
        
        if(founder.issued + blockClaimable > founder.allocated) {
            blockClaimable = founder.allocated - founder.issued;
        }
        
        founder.lastClaimBlock += blockInMnth * pendingBlocks;
        return (blockClaimable,founder.lastClaimBlock);
    }

    /**
    * @dev execute founder claim.
    */
    function _founder(address account) private {
        WalletInfo storage info = founderInfo[account];
        require(info.isActive,"Escrow:: _founder: account is not a founder");
        require(_cliff(foundersInfo.cliff) < block.number,"Escrow:: _founder: cliff isn't over");
        require(info.issued < info.allocated,"Escrow:: _founder: has claimed all issuance" );
       
        (uint claimable, uint time)  = pendingClaim(account);

        if(claimable > 0){
            info.lastClaimBlock = time;
            info.issued += claimable;
            _sendBling(account, claimable,"founders");
        }
    }

    /**
    * @dev execute launch pad claim.
    */
    function _launchPad(address account) private {
        require(_cliff(launchpadInfo.cliff) <= block.number,"Escrow:: _launchPad: cliff isn't over");
        require(launchpadInfo.totalBlings > 0,"Escrow:: _launchPad: has claimed all issuance");
        
        uint amount = launchpadInfo.totalBlings;
        launchpadInfo.totalBlings = 0;
        _sendBling(account, amount,"launchpad");
    }

    /**
    * @dev execute wallets claim.
    */
    function _wallets(address account) private {
        WalletInfo storage info = walletInfo[account];
        require(info.isActive,"Escrow:: _wallets: account is not in wallet list");
        require(_cliff(walletsInfo.cliff) < block.number,"Escrow:: claim: cliff isn't over");
        require(info.allocated > 0,"Escrow:: _wallets: has claimed all issuance");
        
        uint amount = info.allocated;
        info.allocated = 0;
        _sendBling(account, amount,"wallets");
    }

    /**
    * @dev send tokens to founder and launch pad.
    */
    function _sendBling(address account, uint amount, string memory claimType) private {
        require(IERC20(bling).balanceOf(address(this)) >= amount,"Escrow:: _sendbling: insufficient balance");
        IERC20(bling).safeTransfer(account,amount);

         emit Claim(
            account,
            amount,
            claimType
        );
    }

    /**
    * @dev returns cliff blocks.
    */
    function _cliff(uint cliff) private view returns (uint) {
        return startBlock + (blockInMnth * cliff);
    }
}