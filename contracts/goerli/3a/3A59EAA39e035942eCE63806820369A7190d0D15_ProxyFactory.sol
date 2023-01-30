// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import "./Implement.sol";
import "./ImplementWithoutDestruct.sol";
import "./ImplementEthOnly.sol";
import "./ImplementNew.sol";
import "./ImplementNewEth.sol";
import '@openzeppelin/contracts/utils/Address.sol';

contract ProxyFactory {
    address  payable public coldAddress = address(0);
    address  public tokenInstanceERC20 = address(0);
    address  public tokenInstanceERC721 = address(0);
    address  public tokenInstanceERC1155 = address(0);
    uint256 public tokenId  = 0;
    address public owner = address(0);

    event Deployed(address indexed implement, address indexed sender);

    modifier onlyOwner {
        require(msg.sender == owner, 'Unauthorized caller');
        _;
    }

    /// @dev See comment below for explanation of the proxy INIT_CODE
    bytes private constant INIT_CODE =
        hex'604080600a3d393df3fe'
        hex'7300000000000000000000000000000000000000003d36602557'
        hex'3d3d3d3d34865af1603156'
        hex'5b363d3d373d3d363d855af4'
        hex'5b3d82803e603c573d81fd5b3d81f3';
    /// @dev The main address that the deployed proxies will forward to.

    //0x73265c27c849b0e1a62636f6007e8a74dc2a2584aa3d366025573d3d3d3d34865af16031565b363d3d373d3d363d855af45b3d82803e603c573d81fd5b3d81f3
    //
    address payable public immutable mainAddress;

    constructor(address payable addr, address payable _coldAddress, address _owner) public {
        require(addr != address(0), '0x0 is an invalid address');
        mainAddress = addr;

        coldAddress = _coldAddress;
        owner = _owner;
    }

    /**
     * @dev This deploys an extremely minimalist proxy contract with the
     * mainAddress embedded within.
     * Note: The bytecode is explained in comments below this contract.
     * @return dst The new contract address.
     */
    function deployNewInstance(bytes32 salt) external returns (address dst) {
        // copy init code into memory
        // and immutable ExchangeDeposit address onto stack
        bytes memory initCodeMem = INIT_CODE;
        address payable addrStack = mainAddress;
        assembly {
            // Get the position of the start of init code
            let pos := add(initCodeMem, 0x20)
            // grab the first 32 bytes
            let first32 := mload(pos)
            // shift the address bytes 8 bits left
            let addrBytesShifted := shl(8, addrStack)
            // bitwise OR them and add the address into the init code memory
            mstore(pos, or(first32, addrBytesShifted))
            // create the contract
            dst := create2(
                0, // Send no value to the contract
                pos, // Deploy code starts at pos
                74, // Deploy + runtime code is 74 bytes
                salt // 32 byte salt
            )
            // revert if failed
            if eq(dst, 0) {
                revert(0, 0)
            }
        }
    }

    function predictDeployAddress1(bytes32 _salt, bytes memory initCodeMem) public view returns(address){
        //bytes memory initCodeMem = INIT_CODE;
        return address(uint(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            _salt,
            keccak256(abi.encodePacked(initCodeMem))
        ))));
    }

    function deploy2(bytes32 _salt, address _tokenInstanceERC20, address _tokenInstanceERC721, address _tokenInstanceERC1155, uint256 _tokenId) public {
        bytes memory bytecode = type(Implement).creationCode;

        tokenInstanceERC20 = _tokenInstanceERC20;
        tokenInstanceERC721 = _tokenInstanceERC721;
        tokenInstanceERC1155 = _tokenInstanceERC1155;
        tokenId = _tokenId;

        assembly {
            let codeSize := mload(bytecode)
            let newAddr := create2(
                0,
                add(bytecode, 32),
                codeSize,
                _salt
            )
        }

        tokenInstanceERC20 = address(0);
        tokenInstanceERC721 = address(0);
        tokenInstanceERC1155 = address(0);
        tokenId = 0;
    }

    function predictDeployAddress2(bytes32 _salt) public view returns(address){

        return address(uint(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            _salt,
            keccak256(abi.encodePacked(type(Implement).creationCode))
        ))));
    }


    function deploy3(bytes32 _salt, address _tokenInstanceERC20, address _tokenInstanceERC721, address _tokenInstanceERC1155, uint256 _tokenId) public {
        bytes memory bytecode = type(ImplementWithoutDestruct).creationCode;

        tokenInstanceERC20 = _tokenInstanceERC20;
        tokenInstanceERC721 = _tokenInstanceERC721;
        tokenInstanceERC1155 = _tokenInstanceERC1155;
        tokenId = _tokenId;

        assembly {
            let codeSize := mload(bytecode)
            let newAddr := create2(
                0,
                add(bytecode, 32),
                codeSize,
                _salt
            )
        }

        tokenInstanceERC20 = address(0);
        tokenInstanceERC721 = address(0);
        tokenInstanceERC1155 = address(0);
        tokenId = 0;
    }

    function predictDeployAddress3(bytes32 _salt) public view returns(address){

        return address(uint(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            _salt,
            keccak256(abi.encodePacked(type(ImplementWithoutDestruct).creationCode))
        ))));
    }


    function deploy4(bytes32 _salt) public {
        bytes memory bytecode = type(ImplementEthOnly).creationCode;

        assembly {
            let codeSize := mload(bytecode)
            let newAddr := create2(
                0,
                add(bytecode, 32),
                codeSize,
                _salt
            )
        }
    }

    function predictDeployAddress4(bytes32 _salt) public view returns(address){

        return address(uint(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            _salt,
            keccak256(abi.encodePacked(type(ImplementEthOnly).creationCode))
        ))));
    }

    function changeColdAddress(address payable newAddress)
        external
        onlyOwner
    {
        require(newAddress != address(0), '0x0 is an invalid address');
        coldAddress = newAddress;
    }

    function changeOwner(address payable newOwner)
        external
        onlyOwner
    {
        require(newOwner != address(0), '0x0 is an invalid address');
        owner = newOwner;
    }

    function deploy5() public {
        ImplementNew implementInstance = new ImplementNew();
        emit Deployed(address(implementInstance), msg.sender);
    }

    function deploy6() public {
        ImplementNewEth implementInstance = new ImplementNewEth();
        emit Deployed(address(implementInstance), msg.sender);
    }
}




/*
    // PROXY CONTRACT EXPLANATION

    // DEPLOY CODE (will not be returned by web3.eth.getCode())
    // STORE CONTRACT CODE IN MEMORY, THEN RETURN IT
    POS | OPCODE |  OPCODE TEXT      |  STACK                               |
    00  |  6040  |  PUSH1 0x40       |  0x40                                |
    02  |  80    |  DUP1             |  0x40 0x40                           |
    03  |  600a  |  PUSH1 0x0a       |  0x0a 0x40 0x40                      |
    05  |  3d    |  RETURNDATASIZE   |  0x0 0x0a 0x40 0x40                  |
    06  |  39    |  CODECOPY         |  0x40                                |
    07  |  3d    |  RETURNDATASIZE   |  0x0 0x40                            |
    08  |  f3    |  RETURN           |                                      |

    09  |  fe    |  INVALID          |                                      |

    // START CONTRACT CODE

    // Push the ExchangeDeposit address on the stack for DUPing later
    // Also pushing a 0x0 for DUPing later. (saves runtime AND deploy gas)
    // Then use the calldata size as the decider for whether to jump or not
    POS | OPCODE |  OPCODE TEXT      |  STACK                               |
    00  |  73... |  PUSH20 ...       |  {ADDR}                              |
    15  |  3d    |  RETURNDATASIZE   |  0x0 {ADDR}                          |
    16  |  36    |  CALLDATASIZE     |  CDS 0x0 {ADDR}                      |
    17  |  6025  |  PUSH1 0x25       |  0x25 CDS 0x0 {ADDR}                 |
    19  |  57    |  JUMPI            |  0x0 {ADDR}                          |

    // If msg.data length === 0, CALL into address
    // This way, the proxy contract address becomes msg.sender and we can use
    // msg.sender in the Deposit Event
    // This also gives us access to our ExchangeDeposit storage (for forwarding address)
    POS | OPCODE |  OPCODE TEXT      |  STACK                                       |
    1A  |  3d    |  RETURNDATASIZE   |  0x0 0x0 {ADDR}                              |
    1B  |  3d    |  RETURNDATASIZE   |  0x0 0x0 0x0 {ADDR}                          |
    1C  |  3d    |  RETURNDATASIZE   |  0x0 0x0 0x0 0x0 {ADDR}                      |
    1D  |  3d    |  RETURNDATASIZE   |  0x0 0x0 0x0 0x0 0x0 {ADDR}                  |
    1E  |  34    |  CALLVALUE        |  VALUE 0x0 0x0 0x0 0x0 0x0 {ADDR}            |
    1F  |  86    |  DUP7             |  {ADDR} VALUE 0x0 0x0 0x0 0x0 0x0 {ADDR}     |
    20  |  5a    |  GAS              |  GAS {ADDR} VALUE 0x0 0x0 0x0 0x0 0x0 {ADDR} |
    21  |  f1    |  CALL             |  {RES} 0x0 {ADDR}                            |
    22  |  6031  |  PUSH1 0x31       |  0x31 {RES} 0x0 {ADDR}                       |
    24  |  56    |  JUMP             |  {RES} 0x0 {ADDR}                            |

    // If msg.data length > 0, DELEGATECALL into address
    // This will allow us to call gatherErc20 using the context of the proxy
    // address itself.
    POS | OPCODE |  OPCODE TEXT      |  STACK                                 |
    25  |  5b    |  JUMPDEST         |  0x0 {ADDR}                            |
    26  |  36    |  CALLDATASIZE     |  CDS 0x0 {ADDR}                        |
    27  |  3d    |  RETURNDATASIZE   |  0x0 CDS 0x0 {ADDR}                    |
    28  |  3d    |  RETURNDATASIZE   |  0x0 0x0 CDS 0x0 {ADDR}                |
    29  |  37    |  CALLDATACOPY     |  0x0 {ADDR}                            |
    2A  |  3d    |  RETURNDATASIZE   |  0x0 0x0 {ADDR}                        |
    2B  |  3d    |  RETURNDATASIZE   |  0x0 0x0 0x0 {ADDR}                    |
    2C  |  36    |  CALLDATASIZE     |  CDS 0x0 0x0 0x0 {ADDR}                |
    2D  |  3d    |  RETURNDATASIZE   |  0x0 CDS 0x0 0x0 0x0 {ADDR}            |
    2E  |  85    |  DUP6             |  {ADDR} 0x0 CDS 0x0 0x0 0x0 {ADDR}     |
    2F  |  5a    |  GAS              |  GAS {ADDR} 0x0 CDS 0x0 0x0 0x0 {ADDR} |
    30  |  f4    |  DELEGATECALL     |  {RES} 0x0 {ADDR}                      |

    // We take the result of the call, load in the returndata,
    // If call result == 0, failure, revert
    // else success, return
    POS | OPCODE |  OPCODE TEXT      |  STACK                               |
    31  |  5b    |  JUMPDEST         |  {RES} 0x0 {ADDR}                    |
    32  |  3d    |  RETURNDATASIZE   |  RDS {RES} 0x0 {ADDR}                |
    33  |  82    |  DUP3             |  0x0 RDS {RES} 0x0 {ADDR}            |
    34  |  80    |  DUP1             |  0x0 0x0 RDS {RES} 0x0 {ADDR}        |
    35  |  3e    |  RETURNDATACOPY   |  {RES} 0x0 {ADDR}                    |
    36  |  603c  |  PUSH1 0x3c       |  0x3c {RES} 0x0 {ADDR}               |
    38  |  57    |  JUMPI            |  0x0 {ADDR}                          |
    39  |  3d    |  RETURNDATASIZE   |  RDS 0x0 {ADDR}                      |
    3A  |  81    |  DUP2             |  0x0 RDS 0x0 {ADDR}                  |
    3B  |  fd    |  REVERT           |  0x0 {ADDR}                          |
    3C  |  5b    |  JUMPDEST         |  0x0 {ADDR}                          |
    3D  |  3d    |  RETURNDATASIZE   |  RDS 0x0 {ADDR}                      |
    3E  |  81    |  DUP2             |  0x0 RDS 0x0 {ADDR}                  |
    3F  |  f3    |  RETURN           |  0x0 {ADDR}                          |
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import "./ProxyFactory.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract ImplementWithoutDestruct {
    using SafeERC20 for IERC20;
    constructor() public  {
        address factory = msg.sender;
        address payable coldAddress = ProxyFactory(factory).coldAddress();

        address tokenInstanceERC20 = ProxyFactory(factory).tokenInstanceERC20();
        address tokenInstanceERC721 = ProxyFactory(factory).tokenInstanceERC721();
        address tokenInstanceERC1155 = ProxyFactory(factory).tokenInstanceERC1155();
        uint256 tokenId = ProxyFactory(factory).tokenId();

        uint256 EthAmount = address(this).balance;
        if(EthAmount != 0){
            coldAddress.call{ value: EthAmount }('');
        }

        if(tokenInstanceERC20 != address(0)){
            uint256 forwarderBalance = IERC20(tokenInstanceERC20).balanceOf(address(this));
            IERC20(tokenInstanceERC20).safeTransfer(coldAddress, forwarderBalance);
        }

        if(tokenInstanceERC721 != address(0)){
            address owner = IERC721(tokenInstanceERC721).ownerOf(tokenId);
            if (owner == address(this)) {
                IERC721(tokenInstanceERC721).transferFrom(address(this), coldAddress, tokenId);
            }
        }

        if(tokenInstanceERC1155 != address(0)){
            uint256 forwarderBalance = IERC1155(tokenInstanceERC1155).balanceOf(address(this), tokenId);
            if (forwarderBalance != 0) {
                IERC1155(tokenInstanceERC1155).safeTransferFrom(address(this), coldAddress, tokenId, forwarderBalance, '0x');
            }
        }

        //selfdestruct(address(0));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import "./ProxyFactory.sol";
import '@openzeppelin/contracts/utils/Address.sol';

contract ImplementNewEth {
    address factory;
    event Deposit(address indexed receiver, uint256 amount);
    
    modifier onlyOwner {
        require(msg.sender == ProxyFactory(factory).owner(), "not authorized");
        _;
    }

    constructor() public  {
        factory = msg.sender;
    }

    function gatherEth() onlyOwner external {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            return;
        }
        (bool result, ) = ProxyFactory(factory).coldAddress().call{ value: balance }('');
        require(result, 'Could not gather ETH');
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import "./ProxyFactory.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract ImplementNew {
    using SafeERC20 for IERC20;
    address factory;
    event Deposit(address indexed receiver, uint256 amount);

    modifier onlyOwner {
        require(msg.sender == ProxyFactory(factory).owner(), "not authorized");
        _;
    }

    constructor() public  {
        factory = msg.sender;
    }

    function gatherErc20(IERC20 instance) onlyOwner external {
        uint256 forwarderBalance = instance.balanceOf(address(this));
        if (forwarderBalance == 0) {
            return;
        }
        instance.safeTransfer(ProxyFactory(factory).coldAddress(), forwarderBalance);
    }

    function gatherErc721(IERC721 instance, uint256 tokenId) onlyOwner external {
        address owner = instance.ownerOf(tokenId);
        if (owner != address(this)) {
            return;
        }
        instance.transferFrom(address(this), ProxyFactory(factory).coldAddress(), tokenId);
    }

    function gatherErc1155(IERC1155 instance, uint256 tokenId) onlyOwner external {
        uint256 forwarderBalance = instance.balanceOf(address(this), tokenId);
        if (forwarderBalance == 0) {
            return;
        }
        instance.safeTransferFrom(address(this), ProxyFactory(factory).coldAddress(), tokenId, forwarderBalance, '0x');
    }

    function gatherEth() onlyOwner external {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            return;
        }
        (bool result, ) = ProxyFactory(factory).coldAddress().call{ value: balance }('');
        require(result, 'Could not gather ETH');
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import "./ProxyFactory.sol";
import '@openzeppelin/contracts/utils/Address.sol';

contract ImplementEthOnly {

    constructor() public  {
        address factory = msg.sender;
        address payable coldAddress = ProxyFactory(factory).coldAddress();

        coldAddress.call{ value: address(this).balance }('');

        selfdestruct(address(0));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import "./ProxyFactory.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract Implement {
    using SafeERC20 for IERC20;
    constructor() public  {
        address factory = msg.sender;
        address payable coldAddress = ProxyFactory(factory).coldAddress();

        address tokenInstanceERC20 = ProxyFactory(factory).tokenInstanceERC20();
        address tokenInstanceERC721 = ProxyFactory(factory).tokenInstanceERC721();
        address tokenInstanceERC1155 = ProxyFactory(factory).tokenInstanceERC1155();
        uint256 tokenId = ProxyFactory(factory).tokenId();

        uint256 EthAmount = address(this).balance;
        if(EthAmount != 0){
            coldAddress.call{ value: EthAmount }('');
        }

        if(tokenInstanceERC20 != address(0)){
            uint256 forwarderBalance = IERC20(tokenInstanceERC20).balanceOf(address(this));
            IERC20(tokenInstanceERC20).safeTransfer(coldAddress, forwarderBalance);
        }

        if(tokenInstanceERC721 != address(0)){
            address owner = IERC721(tokenInstanceERC721).ownerOf(tokenId);
            if (owner == address(this)) {
                IERC721(tokenInstanceERC721).transferFrom(address(this), coldAddress, tokenId);
            }
        }

        if(tokenInstanceERC1155 != address(0)){
            uint256 forwarderBalance = IERC1155(tokenInstanceERC1155).balanceOf(address(this), tokenId);
            if (forwarderBalance != 0) {
                IERC1155(tokenInstanceERC1155).safeTransferFrom(address(this), coldAddress, tokenId, forwarderBalance, '0x');
            }
        }

        selfdestruct(address(0));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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