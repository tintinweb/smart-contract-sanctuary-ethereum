/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(success, "Addr: cant send val, rcpt revert");
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
        return functionCallWithValue(target, data, value, "Addr: low-level call value fail");
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
        require(address(this).balance >= value, "Addr: insufficient balance call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Addr: low-level static call fail");
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
        require(isContract(target), "Addr: static call non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Addr: low-level del call failed");
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
        require(isContract(target), "Addr: delegate call non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is 0x address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Functional {
    function toString(uint256 value) internal pure returns (string memory) {
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
    
    bool private _reentryKey = false;
    modifier reentryLock {
        require(!_reentryKey, "attempt reenter locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}

contract ERC721 {
	function ownerOf(uint256 tokenId) external view returns (address owner){}
	function proxyTransfer(address from, address to, uint256 tokenId) external{}
    function proxyMint(address _to, uint256 _qty) external {}
}

contract ERC20 {
    function proxyMint(address reciever, uint256 amount) external {}
    function proxyTransfer(address from, address to, uint256 amount) external {}
    function balanceOf(address account) public view returns (uint256) {}
}

contract XaraStore is Ownable, Functional {
    
    ERC721 LAND;
    ERC721 CITY;
    ERC721 VR;
    ERC20 XARACOIN;

	address public payoutWallet;

    uint256 public pricePerCity;
    uint256 public pricePerLand;
    uint256 public pricePerVR;
    uint256 public pricePerPair;
    uint256 public XpricePerCity;
    uint256 public XpricePerLand;
    uint256 public XpricePerVR;
    uint256 public XpricePerPair;

    bool public landActive;
    bool public cityActive;
    bool public vrActive;

    constructor () {
        // temporarily all prices set to .02eth.
        pricePerCity = 250 * (10**15);
        pricePerLand = 200 * (10**15);
        pricePerVR = 200 * (10**15);
        pricePerPair = 400 * (10**15);
        XpricePerCity = 30000000 * (10**18);
        XpricePerLand = 30000000 * (10**18);
        XpricePerVR = 30000000 * (10**18);
        XpricePerPair = 30000000 * (10**18);
    }
    
    // Standard Withdraw function for the owner to pull the contract
    function withdraw() external onlyOwner {
        uint256 sendAmount = address(this).balance;
        (bool success, ) = payoutWallet.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
        
        XARACOIN.proxyTransfer(address(this), payoutWallet, XARACOIN.balanceOf(address(this)));
    }

    // MINT functionality
    // These will only work if minting is allowed by the smart contract
    function mintLandwEth( uint256 qty ) external payable reentryLock {
        require(landActive, "mint not open");
        require(msg.value == (pricePerLand * qty), "wrong payment");
        LAND.proxyMint(_msgSender(), qty);
    }

    function mintCitywEth( uint256 qty ) external payable reentryLock {
        require(cityActive, "mint not open");
        require(msg.value == (pricePerCity * qty), "wrong payment");
        CITY.proxyMint(_msgSender(), qty);
    }

    function mintPairwEth( uint256 qty ) external payable reentryLock {
        require(landActive, "mint not open");
        require(cityActive, "mint not open");
        require(msg.value == (pricePerPair * qty), "wrong payment");
        LAND.proxyMint(_msgSender(), qty);
        CITY.proxyMint(_msgSender(), qty);
    }

    function mintVRwEth( uint256 qty ) external payable reentryLock {
        require(vrActive, "mint not open");
        require(msg.value == (pricePerVR * qty), "wrong payment");

        // just in case
        VR.proxyMint(_msgSender(), qty);
    }

    // mint with XARA

    function mintLandwXARA( uint256 qty ) external reentryLock {
        require(landActive, "mint not open");

        uint256 payment = XpricePerLand * qty;
        XARACOIN.proxyTransfer(_msgSender(), address(this), payment);
        LAND.proxyMint(_msgSender(), qty);
    }

    function mintCitywXARA( uint256 qty ) external reentryLock {
        require(cityActive, "mint not open");

        uint256 payment = XpricePerCity * qty;
        XARACOIN.proxyTransfer(_msgSender(), address(this), payment);
        CITY.proxyMint(_msgSender(), qty);
    }

    function mintPairwXARA( uint256 qty ) external reentryLock {
        require(landActive, "mint not open");
        require(cityActive, "mint not open");

        uint256 payment = XpricePerPair * qty;
        XARACOIN.proxyTransfer(_msgSender(), address(this), payment);
        LAND.proxyMint(_msgSender(), qty);
        CITY.proxyMint(_msgSender(), qty);
    }

    function mintVRwXARA( uint256 qty ) external reentryLock {
        // just in case
        require(vrActive, "mint not open");

        uint256 payment = XpricePerVR * qty;
        XARACOIN.proxyTransfer(_msgSender(), address(this), payment);
        VR.proxyMint(_msgSender(), qty);
    }

    // Setters to activate mints
    function activateLandSales() external onlyOwner { landActive=true; }
    function activateCitySales() external onlyOwner { cityActive=true; }
    function activateVRSales() external onlyOwner { vrActive=true; }
    function deactivateLandSales() external onlyOwner { landActive=false; }
    function deactivateCitySales() external onlyOwner { cityActive=false; }
    function deactivateVRSales() external onlyOwner { vrActive=false; }

	function setPayoutWallet(address newWallet) external onlyOwner {
    	payoutWallet = newWallet;
    }
    

    // Setters for connected smart contracts

    function setLand(address contractAddress) external onlyOwner {
    	LAND = ERC721(contractAddress);
    }
    
    function setCity(address contractAddress) external onlyOwner {
    	CITY = ERC721(contractAddress);
    }
    
    function setVR(address contractAddress) external onlyOwner {
    	VR = ERC721(contractAddress);
    }

    function setCoinContract(address contractAddress) external onlyOwner {
    	XARACOIN = ERC20(contractAddress);
    }

    // Price setting functions
    function setCityPrice(uint256 newPrice) external onlyOwner {
        pricePerCity = newPrice;
    }
    
    function setLandPrice(uint256 newPrice) external onlyOwner {
        pricePerLand = newPrice;
    }
    
    function setVRPrice(uint256 newPrice) external onlyOwner {
        pricePerVR = newPrice;
    }
    
    function setPairPrice(uint256 newPrice) external onlyOwner {
        pricePerPair = newPrice;
    }
    
    function setCityPriceXARA(uint256 newPrice) external onlyOwner {
        XpricePerCity = newPrice;
    }
    
    function setLandPriceXARA(uint256 newPrice) external onlyOwner {
        XpricePerLand = newPrice;
    }
    
    function setVRPriceXARA(uint256 newPrice) external onlyOwner {
        XpricePerVR = newPrice;
    }
    
    function setPairPriceXARA(uint256 newPrice) external onlyOwner {
        XpricePerPair = newPrice;
    }

    
}