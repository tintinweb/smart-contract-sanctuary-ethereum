// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Address.sol';
import "./HeroAccessControl.sol";

contract PreSale is  HeroAccessControl{ 
    using Address for address;

    string[] private tokenURIs = ["39001","51001","58001","78001","151001","80001","89001","168001","173001","61001","13001","107001","73001","132001","154001","72001",
"85001","88001","101001","105001","96001","83001","53001","122001","8001","84001","169001","9001","14001","67001","59001","49001","108001","25001","171001","27001","38001",
"30001","56001","16001","134001","46001","98001","54001","47001","62001","131001","64001","97001","90001","21001","149001","55001","34001","130001","165001","127001","22001",
"146001","93001","33001","86001","36001","141001","162001","79001","140001","65001","82001","70001","125001","71001","10001","126001","87001","60001","152001","2001","68001",
"29001","160001","133001","32001","172001","148001","4001","40001","52001","159001","1001","69001","166001","63001","77001","153001","150001","37001","20001","17001","45001",
"138001","76001","15001","95001","50001","167001","11001","106001","92001","94001","18001","35001"];

    uint256 public startTime;
    uint256 public endTime;
    uint256 public price;
    uint256 public supportMax;
    uint256 public bidMax;
    bool public isStart;
    bool public isFinish;
    uint256 public curSupportNum;

    address private _nftAddress;
    address[] private joinedPerson;
    address[] private FailPerson;

    modifier onlyStart()
    {
        require(isStart==true,"Pre sale has not started or ended!");
       
        _;
    }
    modifier onlyFinish()
    {
        require(isFinish == true, "cur presale is not finish yet!");
        _;
    }

    modifier onlyInit()
    {
        require(isStart==false || isFinish==false);
        _;
    }

    modifier CanFinish()
    {
        //require(block.timestamp >= endTime,"Pre sale has not started or ended!");
        _;
    }
    function GetSupportLeft() view public returns (uint256)
    {
        return supportMax - curSupportNum;
    }

    function IsSupported(address addr) view external returns(bool)
    {
        return Supported(addr);
    }
    
    function Supported(address addr) view internal returns(bool)
    {
        for(uint256 i = 0; i< joinedPerson.length; i++)
        {
            if(addr == joinedPerson[i])
                return true;
        }
        return false;
    }
    function CanSupport() view internal returns(bool)
    {
        if (isFinish == true)
            return false;
        if (block.timestamp>=endTime)
            return false;
        
        return true;
    }

    function setNftAddress(address nftAddress)  external onlyCEO{
        require(nftAddress.isContract()==true,"nftaddress is not a contract!");
        _nftAddress = nftAddress;
    }

    function _ClearData() private onlyCOO {
        startTime = 0;
        endTime = 0;
        price = 0;
        supportMax = 0;
        bidMax = 0;

        isStart = false;
        isFinish = false;
        curSupportNum = 0;
        delete joinedPerson;
    }


    function CreatePreSale( uint256 _startTime,
                            uint256 _endTime, 
                            uint256 _price, 
                            uint256 _supportMax,
                            uint256 _bidMax) external onlyCOO {
        //require(_startTime > block.timestamp ,"startTime must be grater than now!");   
        require(_startTime < _endTime ,"startTime must be less than endTime!");   
        require(_endTime > block.timestamp ,"endTime must be grater than now!");
        require(_price > 0,"price can not eq 0!");
        require(_supportMax > 0,"supportMax can not eq 0!");
        require(_bidMax > 0,"bidMax can not eq 0!");
       
        price = _price;
        startTime = _startTime;
        endTime = _endTime;
        supportMax = _supportMax;
        bidMax = _bidMax;

        if(isStart)
            isStart = false;
        if(isFinish)
            isFinish = false;
        if(curSupportNum>0)
            curSupportNum = 0;
        if(joinedPerson.length>0)
            delete joinedPerson;
    }

    function CompletePreSale() external onlyCOO onlyFinish{
       
        _CompletePreSale();
       
    }
    function _CompletePreSale()  internal  onlyCOO onlyFinish () {

        uint256 i = 1;
        uint256 bidNum = curSupportNum<bidMax?curSupportNum:bidMax;
        address[] memory joinedPersonIndex = joinedPerson;

        uint256 curNum = 0;
        while ( i <= bidNum) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp + i))) % bidNum;

            address tmp = joinedPersonIndex[rand];
            joinedPersonIndex[rand] = joinedPersonIndex[joinedPersonIndex.length-1-curNum];
            joinedPersonIndex[joinedPersonIndex.length-1-curNum] = tmp;
            curNum ++;
            i++;
        }
        for(i=joinedPersonIndex.length-1; i>=0; i--)
        {
            uint256 quality = uint256(keccak256(abi.encodePacked(block.timestamp))) % 10;
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp + 1))) % (tokenURIs.length-1);
           
            if(bidNum > 0)
            {
                bidNum--;
                bytes memory callFun = abi.encodeWithSelector(bytes4(keccak256("spawnHero(uint256,address,string)")), quality, joinedPersonIndex[i],tokenURIs[rand]);
                string memory error;
                bytes memory res = Address.functionCall(_nftAddress,callFun,error);
                uint256 tokenId = abi.decode(res,(uint256));
                if(tokenId==0)
                    FailPerson.push(joinedPersonIndex[i]);
            }
            else
            {
                address(joinedPersonIndex[i]).call{value:price}("");
            }
            if(i==0)
            {
                break;
            }

        }
        _ClearData();
    }
    function bidFail() external onlyCOO{
        require(FailPerson.length > 0,"fail list is empty!");
        address[] memory tmp;
        uint256 failCount = 0;
        for(uint256 i=FailPerson.length-1; i>=0; i--)
        {
            uint256 quality = uint256(keccak256(abi.encodePacked(block.timestamp))) % 10;
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp + 1))) % (tokenURIs.length-1);
           
            bytes memory callFun = abi.encodeWithSelector(bytes4(keccak256("spawnHero(uint256,address,string)")), quality,FailPerson[i] ,tokenURIs[rand]);
            string memory error;
            bytes memory res = Address.functionCall(_nftAddress,callFun,error);
            uint256 tokenId = abi.decode(res,(uint256));
            if(tokenId == 0)
            {
                tmp[failCount] = FailPerson[i];
                failCount++;
            }
        }
        delete FailPerson;
        if(tmp.length > 0)
            FailPerson = tmp;
    }
    function StartPreSale() external onlyCOO onlyInit{
        isStart = true;
        isFinish = false;
    }

    function FinishPreSale() external onlyCOO CanFinish{
        isFinish = true;
        isStart = false;
    }

    function Support() external payable onlyStart CanFinish returns(uint256){
        require(msg.value==price,"prict not match!");
        require(msg.sender.balance > price,"not enough gas!");
        require(msg.sender != address(this),"void sender!");
        require(msg.sender.isContract() != true,"void sender!");
        require(curSupportNum < supportMax, "The upper limit has been reached");
        require(Supported(msg.sender)==false,"You've supported!");
        curSupportNum++;
        joinedPerson.push(msg.sender);
        return GetSupportLeft();
    }


}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract HeroAccessControl {

  address public ceoAddress;
  address payable public cfoAddress;
  address public cooAddress;

  constructor(){
    ceoAddress = msg.sender;
  }

  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  modifier onlyCLevel() {
    require(
      // solium-disable operator-whitespace
      msg.sender == ceoAddress ||
        msg.sender == cfoAddress ||
        msg.sender == cooAddress
      // solium-enable operator-whitespace
    );
    _;
  }

  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setCFO(address payable _newCFO) external onlyCEO {
    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) external onlyCEO {
    cooAddress = _newCOO;
  }

  function withdrawBalance() external onlyCFO {
    cfoAddress.transfer(address(this).balance);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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