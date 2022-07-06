pragma solidity 0.8.12;

import "ds-test/test.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./POC.t.sol";
interface LpTokenLike {
    function set_minter(address) external;
}
contract Lido is ERC20 {
    constructor() ERC20("LIDO","LIDO"){}
    function submit(address) external payable {
        _mint(msg.sender, msg.value);
    }
    function mint(uint amount) external {
        _mint(msg.sender, amount);
    }
    receive() external payable{}
    function rescue() external {
        payable(msg.sender).transfer(address(this).balance);
    }

}
contract Script is DSTest, stdCheats {
    string public constant CURVE_URL = "src/project/20220705_StETH/outs/Curve.json";
    string public constant STETH_URL = "src/project/20220705_StETH/outs/stETH.json";
    string public constant LPTOKEN_URL = "src/project/20220705_StETH/outs/lpToken.json";
    string public constant WETH_URL = "src/project/20220705_StETH/outs/WETH.json";

    Vm public vm = Vm(HEVM_ADDRESS);
    
    address public ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public WETH;
    address public STETH;
    address public LpToken;
    address public Curve;
    Hack public hack;

    address public constant executor = 0xa190E4aDD711E463B1E5D8f42bcf3A242cc45720;
    address public constant gaser = 0x6b1C706c2323bd267c964bf7ce4bB829f6bB647A; /// msg.sender
    address public constant owner = gaser;


    function run() public {
        vm.startBroadcast(owner);

        WETH = deployCode(WETH_URL, "");
        emit log_named_address("WETH", WETH);
        
        STETH = address(new Lido());
        emit log_named_address("STETH", STETH);
        
        LpToken = deployCode(LPTOKEN_URL, abi.encode(
            "STETH_ETH lp",
            "STETH_ETH"
        ));
        emit log_named_address("LPToken", LpToken);
        
        Curve = deployCode(CURVE_URL, abi.encode(
            address(this),//owner
            [ETH, STETH],
            LpToken,
            50,//A
            4000000,//fee
            5000000000//admin fee
        ));
        emit log_named_address("Curve", Curve);
        LpTokenLike(LpToken).set_minter(Curve);
        
        hack = new Hack(executor, gaser, STETH, Curve, WETH);
        emit log_named_address("Hack", address(hack));

        init();
        
        vm.stopBroadcast();

    }
    /// 初始化操作
    /// 1. Curve add liquidity  165,933 gwei ETH - 463_661 gwei stETH
    /// 2. owner deposit 1000 gwei ETH to WETH
    /// 3. owner mint 1000 gwei stETH
    /// 4. owner approve hacker for WETH, stETH
    /// 5. gaser approve hacker for WETH
    function init() public {
        ERC20Like(STETH).approve(Curve, type(uint256).max);
        ERC20Like(STETH).mint(463_661 * 10**9);
        CurveLike(Curve).add_liquidity{value: 165_933 * 10**9}([uint256(165_933 * 10**9), 463_661 * 10**9], 0);
        ERC20Like(WETH).deposit{value: 1000 *10**9}();
        ERC20Like(STETH).mint(1000 * 10**9);
        ERC20Like(WETH).approve(address(hack), type(uint256).max);
        ERC20Like(STETH).approve(address(hack), type(uint256).max);

        hack.addLowerLimitOrder(0.96 *10**9, 50 wei);
        hack.addLowerLimitOrder(0.92 *10**9, 40 wei);
        hack.addUpperLimitOrder(0.97 *10**9, 30 wei);
        hack.addUpperLimitOrder(0.98 *10**9, 20 wei);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

contract DSTest {
    event log                    (string);
    event logs                   (bytes);

    event log_address            (address);
    event log_bytes32            (bytes32);
    event log_int                (int);
    event log_uint               (uint);
    event log_bytes              (bytes);
    event log_string             (string);

    event log_named_address      (string key, address val);
    event log_named_bytes32      (string key, bytes32 val);
    event log_named_decimal_int  (string key, int val, uint decimals);
    event log_named_decimal_uint (string key, uint val, uint decimals);
    event log_named_int          (string key, int val);
    event log_named_uint         (string key, uint val);
    event log_named_bytes        (string key, bytes val);
    event log_named_string       (string key, string val);

    bool public IS_TEST = true;
    bool public failed;

    address constant HEVM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    modifier mayRevert() { _; }
    modifier testopts(string memory) { _; }

    function fail() internal {
        failed = true;
    }

    modifier logs_gas() {
        uint startGas = gasleft();
        _;
        uint endGas = gasleft();
        emit log_named_uint("gas", startGas - endGas);
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }

    function assertTrue(bool condition, string memory err) internal {
        if (!condition) {
            emit log_named_string("Error", err);
            assertTrue(condition);
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }
    function assertEq(address a, address b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes32 a, bytes32 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bytes32]");
            emit log_named_bytes32("  Expected", b);
            emit log_named_bytes32("    Actual", a);
            fail();
        }
    }
    function assertEq(bytes32 a, bytes32 b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq32(bytes32 a, bytes32 b) internal {
        assertEq(a, b);
    }
    function assertEq32(bytes32 a, bytes32 b, string memory err) internal {
        assertEq(a, b, err);
    }

    function assertEq(int a, int b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [int]");
            emit log_named_int("  Expected", b);
            emit log_named_int("    Actual", a);
            fail();
        }
    }
    function assertEq(int a, int b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq(uint a, uint b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [uint]");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            fail();
        }
    }
    function assertEq(uint a, uint b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEqDecimal(int a, int b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal int]");
            emit log_named_decimal_int("  Expected", b, decimals);
            emit log_named_decimal_int("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Expected", b, decimals);
            emit log_named_decimal_uint("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }

    function assertGt(uint a, uint b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGt(uint a, uint b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGt(int a, int b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGt(int a, int b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGtDecimal(int a, int b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }

    function assertGe(uint a, uint b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGe(uint a, uint b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGe(int a, int b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGe(int a, int b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGeDecimal(int a, int b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertLt(uint a, uint b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLt(uint a, uint b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLt(int a, int b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLt(int a, int b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLtDecimal(int a, int b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }

    function assertLe(uint a, uint b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLe(uint a, uint b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLe(int a, int b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLe(int a, int b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLeDecimal(int a, int b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLeDecimal(a, b, decimals);
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertEq(string memory a, string memory b) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log("Error: a == b not satisfied [string]");
            emit log_named_string("  Value a", a);
            emit log_named_string("  Value b", b);
            fail();
        }
    }
    function assertEq(string memory a, string memory b, string memory err) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function checkEq0(bytes memory a, bytes memory b) internal pure returns (bool ok) {
        ok = true;
        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    ok = false;
                }
            }
        } else {
            ok = false;
        }
    }
    function assertEq0(bytes memory a, bytes memory b) internal {
        if (!checkEq0(a, b)) {
            emit log("Error: a == b not satisfied [bytes]");
            emit log_named_bytes("  Expected", a);
            emit log_named_bytes("    Actual", b);
            fail();
        }
    }
    function assertEq0(bytes memory a, bytes memory b, string memory err) internal {
        if (!checkEq0(a, b)) {
            emit log_named_string("Error", err);
            assertEq0(a, b);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.0 <0.9.0;

import "./Vm.sol";

// Wrappers around Cheatcodes to avoid footguns
abstract contract stdCheats {
    using stdStorage for StdStorage;

    // we use custom names that are unlikely to cause collisions so this contract
    // can be inherited easily
    Vm constant vm_std_cheats = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));
    StdStorage std_store_std_cheats;

    // Skip forward or rewind time by the specified number of seconds
    function skip(uint256 time) public {
        vm_std_cheats.warp(block.timestamp + time);
    }

    function rewind(uint256 time) public {
        vm_std_cheats.warp(block.timestamp - time);
    }

    // Setup a prank from an address that has some ether
    function hoax(address who) public {
        vm_std_cheats.deal(who, 1 << 128);
        vm_std_cheats.prank(who);
    }

    function hoax(address who, uint256 give) public {
        vm_std_cheats.deal(who, give);
        vm_std_cheats.prank(who);
    }

    function hoax(address who, address origin) public {
        vm_std_cheats.deal(who, 1 << 128);
        vm_std_cheats.prank(who, origin);
    }

    function hoax(address who, address origin, uint256 give) public {
        vm_std_cheats.deal(who, give);
        vm_std_cheats.prank(who, origin);
    }

    // Start perpetual prank from an address that has some ether
    function startHoax(address who) public {
        vm_std_cheats.deal(who, 1 << 128);
        vm_std_cheats.startPrank(who);
    }

    function startHoax(address who, uint256 give) public {
        vm_std_cheats.deal(who, give);
        vm_std_cheats.startPrank(who);
    }

    // Start perpetual prank from an address that has some ether
    // tx.origin is set to the origin parameter
    function startHoax(address who, address origin) public {
        vm_std_cheats.deal(who, 1 << 128);
        vm_std_cheats.startPrank(who, origin);
    }

    function startHoax(address who, address origin, uint256 give) public {
        vm_std_cheats.deal(who, give);
        vm_std_cheats.startPrank(who, origin);
    }

    // Allows you to set the balance of an account for a majority of tokens
    // Be careful not to break something!
    function tip(address token, address to, uint256 give) public {
        std_store_std_cheats
            .target(token)
            .sig(0x70a08231)
            .with_key(to)
            .checked_write(give);
    }
    function find(address to, bytes4 selector) public returns(bytes32){
        uint256 res = std_store_std_cheats
            .target(to)
            .sig(selector)
            .find();

        return bytes32(res);
        
    }

    // Deploys a contract by fetching the contract bytecode from
    // the artifacts directory
    function deployCode(string memory what, bytes memory args)
        public
        returns (address addr)
    {
        bytes memory bytecode = abi.encodePacked(vm_std_cheats.getCode(what), args);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }

    function deployCode(string memory what)
        public
        returns (address addr)
    {
        bytes memory bytecode = vm_std_cheats.getCode(what);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }

}


library stdError {
    bytes public constant assertionError = abi.encodeWithSignature("Panic(uint256)", 0x01);
    bytes public constant arithmeticError = abi.encodeWithSignature("Panic(uint256)", 0x11);
    bytes public constant divisionError = abi.encodeWithSignature("Panic(uint256)", 0x12);
    bytes public constant enumConversionError = abi.encodeWithSignature("Panic(uint256)", 0x21);
    bytes public constant encodeStorageError = abi.encodeWithSignature("Panic(uint256)", 0x22);
    bytes public constant popError = abi.encodeWithSignature("Panic(uint256)", 0x31);
    bytes public constant indexOOBError = abi.encodeWithSignature("Panic(uint256)", 0x32);
    bytes public constant memOverflowError = abi.encodeWithSignature("Panic(uint256)", 0x41);
    bytes public constant zeroVarError = abi.encodeWithSignature("Panic(uint256)", 0x51);
}

struct StdStorage {
    mapping (address => mapping(bytes4 => mapping(bytes32 => uint256))) slots;
    mapping (address => mapping(bytes4 =>  mapping(bytes32 => bool))) finds;
    
    bytes32[] _keys;
    bytes4 _sig;
    uint256 _depth;
    address _target;
    bytes32 _set;
}


library stdStorage {
    event SlotFound(address who, bytes4 fsig, bytes32 keysHash, uint slot);
    event WARNING_UninitedSlot(address who, uint slot);
    
    Vm constant stdstore_vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

    function sigs(
        string memory sigStr
    )
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(bytes(sigStr)));
    }

    /// @notice find an arbitrary storage slot given a function sig, input data, address of the contract and a value to check against
    // slot complexity:
    //  if flat, will be bytes32(uint256(uint));
    //  if map, will be keccak256(abi.encode(key, uint(slot)));
    //  if deep map, will be keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))));
    //  if map struct, will be bytes32(uint256(keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))))) + structFieldDepth);
    function find(
        StdStorage storage self
    ) 
        internal 
        returns (uint256)
    {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        // calldata to test against
        if (self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
        }
        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        stdstore_vm.record();
        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32*field_depth);
        }
        
        (bytes32[] memory reads, ) = stdstore_vm.accesses(address(who));
        if (reads.length == 1) {
            bytes32 curr = stdstore_vm.load(who, reads[0]);
            if (curr == bytes32(0)) {
                emit WARNING_UninitedSlot(who, uint256(reads[0]));
            }
            if (fdat != curr) {
                require(false, "Packed slot. This would cause dangerous overwriting and currently isnt supported");
            }
            emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[0]));
            self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[0]);
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
        } else if (reads.length > 1) {
            for (uint256 i = 0; i < reads.length; i++) {
                bytes32 prev = stdstore_vm.load(who, reads[i]);
                if (prev == bytes32(0)) {
                    emit WARNING_UninitedSlot(who, uint256(reads[i]));
                }
                // store
                stdstore_vm.store(who, reads[i], bytes32(hex"1337"));
                {
                    (, bytes memory rdat) = who.staticcall(cald);
                    fdat = bytesToBytes32(rdat, 32*field_depth);
                }
                
                if (fdat == bytes32(hex"1337")) {
                    // we found which of the slots is the actual one
                    emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[i]));
                    self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[i]);
                    self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
                    stdstore_vm.store(who, reads[i], prev);
                    break;
                }
                stdstore_vm.store(who, reads[i], prev);
            }
        } else {
            require(false, "No storage use detected for target");
        }

        require(self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))], "NotFound");

        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth; 

        return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        self._target = _target;
        return self;
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        self._sig = _sig;
        return self;
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        self._sig = sigs(_sig);
        return self;
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        self._keys.push(bytes32(uint256(uint160(who))));
        return self;
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        self._keys.push(bytes32(amt));
        return self;
    }
    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        self._keys.push(key);
        return self;
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        self._depth = _depth;
        return self;
    }

    function checked_write(StdStorage storage self, address who) internal {
        checked_write(self, bytes32(uint256(uint160(who))));
    }

    function checked_write(StdStorage storage self, uint256 amt) internal {
        checked_write(self, bytes32(amt));
    }

    function checked_write(StdStorage storage self, bool write) internal {
        bytes32 t;
        assembly {
            t := write
        }
        checked_write(self, t);
    }

    function checked_write(
        StdStorage storage self,
        bytes32 set
    ) internal {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        if (!self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            find(self);
        }
        bytes32 slot = bytes32(self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]);

        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32*field_depth);
        }
        bytes32 curr = stdstore_vm.load(who, slot);

        if (fdat != curr) {
            require(false, "Packed slot. This would cause dangerous overwriting and currently isnt supported");
        }
        stdstore_vm.store(who, slot, set);
        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth; 
    }

    function bytesToBytes32(bytes memory b, uint offset) public pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function flatten(bytes32[] memory b) private pure returns (bytes memory)
    {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.0;
pragma experimental ABIEncoderV2;


interface Vm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;
    // Set block.height (newHeight)
    function roll(uint256) external;
    // Set block.basefee (newBasefee)
    function fee(uint256) external;
    // Set block.chainid
    function chainId(uint256) external;
    // Loads a storage slot from an address (who, slot)
    function load(address,bytes32) external returns (bytes32);
    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address,bytes32,bytes32) external;
    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
    // Gets the nonce of an account
    function getNonce(address) external returns (uint64);
    // Sets the nonce of an account; must be higher than the current nonce of the account
    function setNonce(address, uint64) external;
    // Performs a foreign function call via terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address,address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address,address) external;
    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
    // Sets an address' balance, (who, newBalance)
    function deal(address, uint256) external;
    // Sets an address' code, (who, newCode)
    function etch(address, bytes calldata) external;
    // Expects an error on next call
    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;
    function expectRevert() external;
    // Record all storage reads and writes
    function record() external;
    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);
    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool,bool,bool,bool) external;
    function expectEmit(bool,bool,bool,bool,address) external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address,bytes calldata,bytes calldata) external;
    // Mocks a call to an address with a specific msg.value, returning specified data.
    // Calldata match takes precedence over msg.value in case of ambiguity.
    function mockCall(address,uint256,bytes calldata,bytes calldata) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address,bytes calldata) external;
    // Expect a call to an address with the specified msg.value and calldata
    function expectCall(address,uint256,bytes calldata) external;
    // Gets the code from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata) external returns (bytes memory);
    // Labels an address in call traces
    function label(address, string calldata) external;
    // If the condition is false, discard this run's fuzz inputs and generate new ones
    function assume(bool) external;
    // Set block.coinbase (who)
    function coinbase(address) external;
    // Using the address that calls the test contract, has the next call (at this call depth only) create a transaction that can later be signed and sent onchain
    function broadcast() external;
    // Has the next call (at this call depth only) create a transaction with the address provided as the sender that can later be signed and sent onchain
    function broadcast(address) external;
    // Using the address that calls the test contract, has the all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast() external;
    // Has the all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast(address) external;
    // Stops collecting onchain transactions
    function stopBroadcast() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

pragma solidity 0.8.12;

import "ds-test/test.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
contract Addr  {
    address public constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; /// index=0
    address public constant STETH_ETH = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022; /// ETH:0, stETH:1
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}   
contract AddrBase is Addr, DSTest, stdCheats {}
interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function approve(address,uint256) external returns (bool);
    function transfer(address,uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function deposit() external payable;
    function withdraw(uint256) external;
    function submit(address) external payable;
    function mint(uint256) external;
}
interface CurveLike {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) payable external returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx) view external returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) payable external returns (uint256);
    function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts) external returns (uint256[2] memory);
}
contract Hack is Ownable {
    address public stETH;
    address public STETH_ETH;
    address public WETH;

    uint256 public constant CALC_AMOUNT = 1 *10**9;
    uint256 public constant MIN_RATIO = 80;
    struct LimitOrder {
        uint256 price;
        uint256 amount;
    }
    LimitOrder[] public lowerLimitOrders;
    LimitOrder[] public upperLimitOrders;
    
    address public executor;
    address public gaser;

    event AddLowerLimitOrder(uint256 indexed index,uint256 indexed LimitOrderPrice,uint256 LimitOrderAmount);
    event AddUpperLimitOrder(uint256 indexed index,uint256 indexed LimitOrderPrice,uint256 LimitOrderAmount);
    event CancelLimitOrder(uint256 indexed LimitOrderPrice, uint256 LimitOrderAmount, bool isUpper);
    event FillLimitOrder(uint256 indexed price, uint256 indexed LimitOrderPrice, uint256 LimitOrderAmount, bool isUpper);
    event Swap(uint256 indexed price, uint256 amountIn, uint256 amountOut, bool isBuy);
    event Bribe(address coinbase, uint256 bribeAmount);
    constructor(address _executor, address _gaser, address _stETH, address _STETH_ETH, address _WETH) {
        executor = _executor;
        gaser = _gaser;

        stETH = _stETH;
        STETH_ETH = _STETH_ETH;
        WETH = _WETH;

        ERC20Like(stETH).approve(STETH_ETH, type(uint256).max);

    }
    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor");
        _;
    }
    function getPrice() public view returns (uint) {
        uint256 price = CurveLike(STETH_ETH).get_dy(int128(1), int128(0), CALC_AMOUNT);
        return price;
    }
    function addLowerLimitOrder(uint256 _price, uint256 _amount) public onlyOwner() {
        uint price = getPrice();
        require(_price < price, "should put lowerLimitOrder below current price");

        LimitOrder memory limitOrder = LimitOrder(
            _price,
            _amount
        );
        lowerLimitOrders.push(limitOrder);

        emit AddLowerLimitOrder(lowerLimitOrders.length, _price, _amount);

    }
    function addUpperLimitOrder(uint256 _price, uint256 _amount) public onlyOwner() {
        uint price = getPrice();
        require(_price > price, "should put upperLimitOrder price above the current price");

        LimitOrder memory limitOrder = LimitOrder(
            _price,
            _amount
        );
        upperLimitOrders.push(limitOrder);
        emit AddUpperLimitOrder(upperLimitOrders.length, _price, _amount);
    }
    function cancelLimitOrder(uint256 _price, bool isUpper) public onlyOwner() {
        /// swap & pop
        if (isUpper) {
            uint length = upperLimitOrders.length;
            for (uint i = 0; i < length;) {
                LimitOrder memory limitOrder = upperLimitOrders[i];
                if (_price == limitOrder.price) {
                    /// swap & pop
                    swapAndPop(upperLimitOrders, i);
                    length -= 1;

                    emit CancelLimitOrder(_price,limitOrder.amount, isUpper);
                } else {
                    i++;
                }
            }
        } else {
            uint length = lowerLimitOrders.length;
            for (uint i = 0; i < length;) {
                LimitOrder memory limitOrder = lowerLimitOrders[i];
                if (_price == limitOrder.price) {
                    /// swap & pop
                    swapAndPop(lowerLimitOrders, i);
                    length -= 1;

                    emit CancelLimitOrder(_price, limitOrder.amount, isUpper);
                } else {
                    i++;
                }
            }
        }
    }
    function swapAndPop(LimitOrder[] storage limitOrders, uint i) internal {
        uint length = limitOrders.length;
        limitOrders[i] = limitOrders[length - 1];
        delete limitOrders[length - 1];
    }
    function isQualify() public view returns (bool) {
        uint256 price = getPrice();
        uint amountBuy;
        uint amountSell;
        for (uint i = 0; i < lowerLimitOrders.length; i++) {
            LimitOrder memory limitOrder = lowerLimitOrders[i];
            if (price <= limitOrder.price) {
                amountBuy += limitOrder.amount;
            }
        }
        for (uint i = 0; i < upperLimitOrders.length; i++) {
            LimitOrder memory limitOrder = upperLimitOrders[i];
            if (price >= limitOrder.price) {
                amountSell += limitOrder.amount;
            }
        }
        return (amountBuy > 0 || amountSell > 0);
    }

    /// 具体执行, 这里考虑使用flashbot，给coinbase行贿的方式
    function start(uint256 _bribe) public onlyExecutor() {
        uint256 price = getPrice();
        uint amountBuy;
        uint amountSell;
        uint priceBuyHighest;
        uint priceSellLowest;
        uint length = lowerLimitOrders.length;
        for (uint i = 0; i < length;) {
            LimitOrder memory limitOrder = lowerLimitOrders[i];
            if (price <= limitOrder.price) {
                amountBuy += limitOrder.amount;
                swapAndPop(lowerLimitOrders, i);
                length -= 1;

                priceBuyHighest = limitOrder.price > priceBuyHighest ? limitOrder.price : priceBuyHighest;
                emit FillLimitOrder(price, limitOrder.price, limitOrder.amount, false);
            } else {
                i++;
            }
        }
        length = upperLimitOrders.length;
        for (uint i = 0; i < length; ) {
            LimitOrder memory limitOrder = upperLimitOrders[i];
            if (price >= limitOrder.price) {
                amountSell += limitOrder.amount;
                swapAndPop(upperLimitOrders, i);
                length -= 1;

                priceSellLowest = limitOrder.price < priceSellLowest ? limitOrder.price : priceSellLowest;
                emit FillLimitOrder(price, limitOrder.price, limitOrder.amount, true);
            } else {
                i++;
            }
        }
        require(amountBuy > 0 || amountSell > 0, "not qualify");
        if (amountBuy > amountSell) {
            uint targetAmountBuy = 0;
            if (amountSell > 0) {
                targetAmountBuy = CurveLike(STETH_ETH).get_dy(int128(1), int128(0), amountSell);
            }
            uint amount = amountBuy - targetAmountBuy;
            require(ERC20Like(WETH).transferFrom(owner(),address(this),amount), "insufficient amount, need to approve more WETH");
            ERC20Like(WETH).withdraw(amount);
            uint minAmount = amount * 1e18 / priceBuyHighest * MIN_RATIO / 100;
            uint amountOut = CurveLike(STETH_ETH).exchange{value: amount}(int128(0),int128(1),amount, minAmount);
            ERC20Like(stETH).transfer(owner(), amountOut);
            emit Swap(price, amount, amountOut, true);
        } else if (amountBuy < amountSell) {
            uint targetAmountSell = 0;
            if (amountBuy > 0) {
                targetAmountSell = CurveLike(STETH_ETH).get_dy(int128(0), int128(1), amountBuy);
            }
            uint amount = amountSell - targetAmountSell;
            require(ERC20Like(stETH).transferFrom(owner(), address(this), amount), "insufficient amount, need to approve more stETH");
            uint minAmount = amount * priceSellLowest / 1e18 * MIN_RATIO / 100;
            uint amountOut = CurveLike(STETH_ETH).exchange(int128(1), int128(0), amount, minAmount);
            ERC20Like(WETH).deposit{value: amountOut}();
            ERC20Like(WETH).transfer(owner(), amountOut);
            emit Swap(price, amount, amountOut, false);
        }
        if (_bribe > 0) {
            ERC20Like(WETH).transferFrom(gaser, address(this), _bribe);
            ERC20Like(WETH).withdraw(_bribe);
            payable(address(block.coinbase)).transfer(_bribe);
            emit Bribe(block.coinbase, _bribe);
        }

    }
    receive() external payable {}

    function rescue(address _token, uint ethAmount) public onlyOwner() {
        if (isContract(_token)) {
            ERC20Like(_token).transfer(owner(), ERC20Like(_token).balanceOf(address(this)));
        }
        if (ethAmount > 0) {
            payable(address(owner())).transfer(ethAmount);
        }

    }
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }


}

contract POC is DSTest, stdCheats, Addr {
    Vm public vm = Vm(HEVM_ADDRESS);
    Hack public hack;
    function setUp() public {
        hack = new Hack(stETH, STETH_ETH, WETH, address(this), address(this));
        ERC20Like(WETH).approve(address(hack), type(uint256).max);
        ERC20Like(stETH).approve(address(hack), type(uint256).max);

        ERC20Like(WETH).approve(STETH_ETH, type(uint256).max);
        ERC20Like(stETH).approve(STETH_ETH, type(uint256).max);

        /// set upper limit and lower limit
        uint price = hack.getPrice(); /// 0.968044845481160395
        emit log_named_uint("price", price);
        hack.addLowerLimitOrder(price * 99 / 100, 50 ether);
        hack.addLowerLimitOrder(price * 98 / 100, 40 ether);
        hack.addUpperLimitOrder(price * 101 / 100, 50 ether);
        hack.addUpperLimitOrder(price * 102 / 100, 40 ether);

        /// prepare WETH
        ERC20Like(WETH).deposit{value: 100000 ether}();
        /// prepare stETH
        ERC20Like(stETH).submit{value: 100000 ether}(address(this));

    }
    function test_Start() public {
        /// dump stETH, pull the price down, trigger the lower limit order
        CurveLike(STETH_ETH).exchange(int128(1), int128(0), 100000 ether, 1);
        uint price = hack.getPrice(); /// 0.968044845481160395
        emit log_named_uint("price", price);
        bool isQualify = hack.isQualify();
        emit log_named_string("is Qualify", isQualify ? "true" : "false");
        hack.start(1);
        hack.lowerLimitOrders(0);
        hack.upperLimitOrders(0);
    }
    function test_Start2() public {
        CurveLike(STETH_ETH).exchange{value: 100000 ether}(int128(0), int128(1), 100000 ether, 1);
        uint price = hack.getPrice(); /// 0.968044845481160395
        emit log_named_uint("price", price);
        bool isQualify = hack.isQualify();
        emit log_named_string("is Qualify", isQualify ? "true" : "false");
        hack.start(2);
        hack.lowerLimitOrders(0);
        hack.upperLimitOrders(0);
    }
    function test_Start3() public {
        CurveLike(STETH_ETH).exchange(int128(1), int128(0), 100000 ether, 1);
        /// 
        uint price = hack.getPrice();
        (uint lowerP, ) = hack.lowerLimitOrders(0);
        hack.cancelLimitOrder(lowerP, false);
        hack.start(3);
        hack.lowerLimitOrders(0);
        hack.upperLimitOrders(0);
    }
    function test_Rescue() public {
        payable(address(hack)).transfer(100 ether);
        hack.rescue(address(0), 10 ether);
        ERC20Like(WETH).transfer(address(hack), 100 ether);
        hack.rescue(WETH, 0);
    }
    receive() external payable{}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
 import "ds-test/test.sol";
abstract contract Context is DSTest {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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