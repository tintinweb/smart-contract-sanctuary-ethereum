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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
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

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract HydraS1Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [21074967200675833971694321405702662955984852337891003729341862308014465091452,
             16239566217647036198645933285498253749256054886973470339239684485270885956215],
            [14924257777088158779814616413831190210340570055971329881985623797786208579282,
             10691380211893723662649095657547419535091326341642023697740441408712196201241]
        );
        vk.IC = new Pairing.G1Point[](11);
        
        vk.IC[0] = Pairing.G1Point( 
            14332859318300903602726726264518824941700928929282684002435956418180934208314,
            11010749003547904817353526241437007890990754516996336072224574623875025377423
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            2136290885913054145381996007250377116979702880963736541448661471227331823946,
            16478231370049311298201665249480417699291014313053020794936431185017549556827
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            11831300866857088406929919928941784545144969975593177329559161446617438195466,
            6212358893906500172443792051290438473622355930607853876624440242040853628103
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            11027061483863563635024092338688057759119259003999562030510583437629731262092,
            18703534155477682738912654177120374525115379622616054126469182046526229513482
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            5523693478445700924248952252775285397892361419050998402369822953526549273401,
            8889687222792584883230263427382199395996373461132719158639486586169270808032
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            9702182220653517435416079822286914219819968872418769724548006464149773705655,
            2094706826455142351238572992406099275644029039658272241018450229757956388290
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            20008324557473975468116486068503947078574162824833993787007339201140363527840,
            15559404536541574633494494405920841139841997225456025716654841400908437406204
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            17924443494052582129092305495378995299567475106103367984498002018459557174119,
            9088182083877679129116610749841031638132439262255694574913529956369104180811
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            4355321544872670285577148636981605601033459920862911308603388095263271825855,
            8247186830718786712704685520325741324626242372309587992285635877026354223913
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            1431121236098128131877300059605348195513542435201734750258285880710002147635,
            15786550927466006816597517192876275260815796964699076200080242673772884486204
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            4184258059965512180880294621674402722022660157642690877278591478197191563084,
            11861570517592150750607172447825960420737610464768293128184723301589231686194
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[10] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {IHydraS1Base} from './IHydraS1Base.sol';
import {Initializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';

// Protocol imports
import {Request, Attestation, Claim} from '../../../core/libs/Structs.sol';

// Imports related to Hydra S1 ZK Proving Scheme
import {HydraS1Verifier, HydraS1Lib, HydraS1Claim, HydraS1ProofData, HydraS1ProofInput, HydraS1GroupProperties} from '../libs/HydraS1Lib.sol';
import {ICommitmentMapperRegistry} from '../../../periphery/utils/CommitmentMapperRegistry.sol';
import {IAvailableRootsRegistry} from '../../../periphery/utils/AvailableRootsRegistry.sol';

/**
 * @title Hydra-S1 Base Attester
 * @author Sismo
 * @notice Abstract contract that facilitates the use of the Hydra-S1 ZK Proving Scheme.
 * Hydra-S1 is single source, single group: it allows users to verify they are part of one and only one group at a time
 * It is inherited by the family of Hydra-S1 attesters.
 * It contains the user input checking and the ZK-SNARK proof verification.
 * We invite readers to refer to:
 *    - https://hydra-s1.docs.sismo.io for a full guide through the Hydra-S1 ZK Attestations
 *    - https://hydra-s1-circuits.docs.sismo.io for circuits, prover and verifiers of Hydra-S1
 
 
 **/
abstract contract HydraS1Base is IHydraS1Base, Initializable {
  using HydraS1Lib for HydraS1ProofData;

  // ZK-SNARK Verifier
  HydraS1Verifier immutable VERIFIER;
  // Registry storing the Commitment Mapper EdDSA Public key
  ICommitmentMapperRegistry immutable COMMITMENT_MAPPER_REGISTRY;
  // Registry storing the World Tree Roots of the Attester's available ClaimData
  IAvailableRootsRegistry immutable AVAILABLE_ROOTS_REGISTRY;

  /*******************************************************
    INITIALIZATION FUNCTIONS                           
  *******************************************************/
  /**
   * @dev Constructor. Initializes the contract
   * @param hydraS1VerifierAddress ZK Snark Verifier contract
   * @param availableRootsRegistryAddress Registry where is the Available Data (World Merkle Roots)
   * @param commitmentMapperAddress Commitment mapper's public key registry
   */
  constructor(
    address hydraS1VerifierAddress,
    address availableRootsRegistryAddress,
    address commitmentMapperAddress
  ) {
    VERIFIER = HydraS1Verifier(hydraS1VerifierAddress);
    AVAILABLE_ROOTS_REGISTRY = IAvailableRootsRegistry(availableRootsRegistryAddress);
    COMMITMENT_MAPPER_REGISTRY = ICommitmentMapperRegistry(commitmentMapperAddress);
  }

  /**
   * @dev Getter of Hydra-S1 Verifier contract
   */
  function getVerifier() external view returns (HydraS1Verifier) {
    return VERIFIER;
  }

  /**
   * @dev Getter of Commitment Mapper Registry contract
   */
  function getCommitmentMapperRegistry() external view returns (ICommitmentMapperRegistry) {
    return COMMITMENT_MAPPER_REGISTRY;
  }

  /**
   * @dev Getter of Roots Registry Contract
   */
  function getAvailableRootsRegistry() external view returns (IAvailableRootsRegistry) {
    return AVAILABLE_ROOTS_REGISTRY;
  }

  /*******************************************************
    Hydra-S1 SPECIFIC FUNCTIONS
  *******************************************************/

  /**
   * @dev MANDATORY: must be implemented to return the ticket identifier from a user request
   * so it can be checked against snark input
   * ticket = hash(sourceSecretHash, ticketIdentifier), which is verified inside the snark
   * users bring sourceSecretHash as private input which guarantees privacy

   * This function MUST be implemented by Hydra-S1 attesters.
   * This is the core function that implements the logic of tickets

   * Do they get one ticket per claim?
   * Do they get 2 tickets per claim?
   * Do they get 1 ticket per claim, every month?
   * Take a look at Hydra-S1 Simple Attester for an example
   * @param claim user claim: part of a group of accounts, with a claimedValue for their account
   */
  function _getTicketIdentifierOfClaim(HydraS1Claim memory claim)
    internal
    view
    virtual
    returns (uint256);

  /**
   * @dev Checks whether the user claim and the snark public input are a match
   * @param claim user claim
   * @param input snark public input
   */
  function _validateInput(HydraS1Claim memory claim, HydraS1ProofInput memory input)
    internal
    view
    virtual
  {
    if (input.accountTreeValue != claim.groupId)
      revert AccountTreeValueMismatch(claim.groupId, input.accountTreeValue);

    if (input.isStrict == claim.groupProperties.isScore)
      revert IsStrictMismatch(claim.groupProperties.isScore, input.isStrict);

    if (input.destination != claim.destination)
      revert DestinationMismatch(claim.destination, input.destination);

    if (input.chainId != block.chainid) revert ChainIdMismatch(block.chainid, input.chainId);

    if (input.value != claim.claimedValue) revert ValueMismatch(claim.claimedValue, input.value);

    if (!AVAILABLE_ROOTS_REGISTRY.isRootAvailableForMe(input.worldRoot))
      revert WorldRootMismatch(input.worldRoot);

    uint256[2] memory commitmentMapperPubKey = COMMITMENT_MAPPER_REGISTRY.getEdDSAPubKey();
    if (
      input.commitmentMapperPubKey[0] != commitmentMapperPubKey[0] ||
      input.commitmentMapperPubKey[1] != commitmentMapperPubKey[1]
    )
      revert CommitmentMapperPubKeyMismatch(
        commitmentMapperPubKey[0],
        commitmentMapperPubKey[1],
        input.commitmentMapperPubKey[0],
        input.commitmentMapperPubKey[1]
      );

    uint256 ticketIdentifier = _getTicketIdentifierOfClaim(claim);

    if (input.ticketIdentifier != ticketIdentifier)
      revert TicketIdentifierMismatch(ticketIdentifier, input.ticketIdentifier);
  }

  /**
   * @dev verify the groth16 mathematical proof
   * @param data snark public input
   */
  function _verifyProof(HydraS1ProofData memory data) internal view virtual {
    try VERIFIER.verifyProof(data.proof.a, data.proof.b, data.proof.c, data.input) returns (
      bool success
    ) {
      if (!success) revert InvalidGroth16Proof('');
    } catch Error(string memory reason) {
      revert InvalidGroth16Proof(reason);
    } catch Panic(
      uint256 /*errorCode*/
    ) {
      revert InvalidGroth16Proof('');
    } catch (
      bytes memory /*lowLevelData*/
    ) {
      revert InvalidGroth16Proof('');
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {HydraS1Verifier, HydraS1Lib, HydraS1ProofData} from '../libs/HydraS1Lib.sol';
import {ICommitmentMapperRegistry} from '../../../periphery/utils/CommitmentMapperRegistry.sol';
import {IAvailableRootsRegistry} from '../../../periphery/utils/AvailableRootsRegistry.sol';

// todo: explain well what is specific to this attester
interface IHydraS1Base {
  error ClaimsLengthDifferentThanOne(uint256 claimLength);
  error WorldRootMismatch(uint256 inputRoot);
  error DestinationMismatch(address expectedDestination, address inputDestination);
  error CommitmentMapperPubKeyMismatch(
    uint256 expectedX,
    uint256 expectedY,
    uint256 inputX,
    uint256 inputY
  );
  error TicketIdentifierMismatch(uint256 expectedTicketIdentifier, uint256 ticketIdentifier);
  error IsStrictMismatch(bool expectedStrictness, bool strictNess);
  error ChainIdMismatch(uint256 expectedChainId, uint256 chainId);
  error ValueMismatch(uint256 expectedValue, uint256 inputValue);
  error AccountTreeValueMismatch(uint256 expectedAccountTreeValue, uint256 inputAccountTreeValue);
  error InvalidGroth16Proof(string reason);

  /**
   * @dev Getter of Hydra-S1 Verifier contract
   */
  function getVerifier() external view returns (HydraS1Verifier);

  /**
   * @dev Getter of Commitment Mapper Registry contract
   */
  function getCommitmentMapperRegistry() external view returns (ICommitmentMapperRegistry);

  /**
   * @dev Getter of Roots Registry Contract
   */
  function getAvailableRootsRegistry() external view returns (IAvailableRootsRegistry);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {Attestation} from '../../../core/libs/Structs.sol';
import {IAttester} from '../../../core/interfaces/IAttester.sol';
import {CommitmentMapperRegistry} from '../../../periphery/utils/CommitmentMapperRegistry.sol';
import {AvailableRootsRegistry} from '../../../periphery/utils/AvailableRootsRegistry.sol';
import {HydraS1Lib, HydraS1ProofData, HydraS1ProofInput} from './../libs/HydraS1Lib.sol';
import {IHydraS1Base} from './../base/IHydraS1Base.sol';

// todo: explain well what is specific to this attester
interface IHydraS1SoulboundAttester is IHydraS1Base, IAttester {
  struct TicketData {
    address destination;
    uint32 cooldownStart;
  }
  error NotAttestationOwner(uint256 ticket, address sender);
  error TicketFrozen(uint256 ticketData);
  error TicketUsedAndOnCooldown(TicketData ticketData);
  error CollectionIdOutOfBound(uint256 collectionId);

  event TicketDestinationUpdated(uint256 ticket, address newOwner);
  event TicketSetOnCooldown(uint256 ticket);

  /**
   * @dev returns whether a ticket is on cooldown or not
   * @param userTicket ticket used
   **/
  function isTicketOnCooldown(uint256 userTicket) external view returns (bool);

  /**
   * @dev Getter, returns the data linked to a ticket
   * @param userTicket ticket used
   **/
  function getTicketData(uint256 userTicket) external view returns (TicketData memory);

  /**
   * @dev Getter, returns the last attestation destination of a ticket
   * @param userTicket ticket used
   **/
  function getDestinationOfTicket(uint256 userTicket) external view returns (address);

  /**
   * @dev Getter
   * returns of the first collection in which the attester is supposed to record
   **/
  function AUTHORIZED_COLLECTION_ID_FIRST() external view returns (uint256);

  /**
   * @dev Getter
   * returns of the last collection in which the attester is supposed to record
   **/
  function AUTHORIZED_COLLECTION_ID_LAST() external view returns (uint256);

  /**
   * @dev Getter
   * returns of the duration of the cooldown period after having used a ticket
   **/
  function SOULBOUND_COOLDOWN_DURATION() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Claim, Request} from '../../../core/libs/Structs.sol';
import {HydraS1Verifier} from '@sismo-core/hydra-s1-verifier-contracts/HydraS1Verifier.sol';

// user Hydra-S1 claim retrieved form his request
struct HydraS1Claim {
  uint256 groupId; // user claims to have an account in this group
  uint256 claimedValue; // user claims this value for its account in the group
  address destination; // user claims to own this destination[]
  HydraS1GroupProperties groupProperties; // user claims the group has the following properties
}

struct HydraS1GroupProperties {
  uint128 index;
  uint32 generationTimestamp;
  bool isScore;
}

struct HydraS1CircomSnarkProof {
  uint256[2] a;
  uint256[2][2] b;
  uint256[2] c;
}

struct HydraS1ProofData {
  HydraS1CircomSnarkProof proof;
  uint256[10] input;
  // destination
  // chainId
  // commitmentMapperPubKey.x
  // commitmentMapperPubKey.y
  // worldMerkleTreeRoot
  // ticketIdentifier
  // ticket
  // selectedAccountValue
  // accountTreeValue
  // isStrictValue
}

struct HydraS1ProofInput {
  address destination;
  uint256 chainId;
  uint256 worldRoot;
  uint256 ticketIdentifier;
  uint256 ticket;
  uint256 value;
  uint256 accountTreeValue;
  bool isStrict;
  uint256[2] commitmentMapperPubKey;
}

library HydraS1Lib {
  uint256 constant SNARK_FIELD =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;

  error GroupIdAndPropertiesMismatch(uint256 expectedGroupId, uint256 groupId);

  function _input(HydraS1ProofData memory self) internal pure returns (HydraS1ProofInput memory) {
    return
      HydraS1ProofInput(
        _getDestination(self),
        _getChainId(self),
        _getWorldRoot(self),
        _getExpectedExternalNullifier(self),
        _getTicket(self),
        _getValue(self),
        _getAccountTreeValue(self),
        _getIsStrict(self),
        _getCommitmentMapperPubKey(self)
      );
  }

  function _claim(Request memory self) internal pure returns (HydraS1Claim memory) {
    Claim memory claim = self.claims[0];
    _validateClaim(claim);

    HydraS1GroupProperties memory groupProperties = abi.decode(
      claim.extraData,
      (HydraS1GroupProperties)
    );

    return (HydraS1Claim(claim.groupId, claim.claimedValue, self.destination, groupProperties));
  }

  function _toCircomFormat(HydraS1ProofData memory self)
    internal
    pure
    returns (
      uint256[2] memory,
      uint256[2][2] memory,
      uint256[2] memory,
      uint256[10] memory
    )
  {
    return (self.proof.a, self.proof.b, self.proof.c, self.input);
  }

  function _getDestination(HydraS1ProofData memory self) internal pure returns (address) {
    return address(uint160(self.input[0]));
  }

  function _getChainId(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[1];
  }

  function _getCommitmentMapperPubKey(HydraS1ProofData memory self)
    internal
    pure
    returns (uint256[2] memory)
  {
    return [self.input[2], self.input[3]];
  }

  function _getWorldRoot(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[4];
  }

  function _getExpectedExternalNullifier(HydraS1ProofData memory self)
    internal
    pure
    returns (uint256)
  {
    return self.input[5];
  }

  function _getTicket(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[6];
  }

  function _getValue(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[7];
  }

  function _getAccountTreeValue(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[8];
  }

  function _getIsStrict(HydraS1ProofData memory self) internal pure returns (bool) {
    return self.input[9] == 1;
  }

  function _getTicket(bytes calldata self) internal pure returns (uint256) {
    HydraS1ProofData memory snarkProofData = abi.decode(self, (HydraS1ProofData));
    uint256 userTicket = uint256(_getTicket(snarkProofData));
    return userTicket;
  }

  function _generateGroupIdFromProperties(
    uint128 groupIndex,
    uint32 generationTimestamp,
    bool isScore
  ) internal pure returns (uint256) {
    return
      _generateGroupIdFromEncodedProperties(
        _encodeGroupProperties(groupIndex, generationTimestamp, isScore)
      );
  }

  function _generateGroupIdFromEncodedProperties(bytes memory encodedProperties)
    internal
    pure
    returns (uint256)
  {
    return uint256(keccak256(encodedProperties)) % HydraS1Lib.SNARK_FIELD;
  }

  function _encodeGroupProperties(
    uint128 groupIndex,
    uint32 generationTimestamp,
    bool isScore
  ) internal pure returns (bytes memory) {
    return abi.encode(groupIndex, generationTimestamp, isScore);
  }

  function _validateClaim(Claim memory claim) internal pure {
    uint256 expectedGroupId = _generateGroupIdFromEncodedProperties(claim.extraData);
    if (claim.groupId != expectedGroupId)
      revert GroupIdAndPropertiesMismatch(expectedGroupId, claim.groupId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {IHydraS1SoulboundAttester} from '../interfaces/IHydraS1SoulboundAttester.sol';

// Core protocol Protocol imports
import {Request, Attestation, Claim} from '../../../core/libs/Structs.sol';
import {Attester, IAttester, IAttestationsRegistry} from '../../../core/Attester.sol';

// Imports related to HydraS1 Proving Scheme
import {HydraS1Base, HydraS1Lib, HydraS1ProofData, HydraS1ProofInput, HydraS1Claim} from '../base/HydraS1Base.sol';

/**
 * @title  Hydra-S1 Soulbound Attester
 * @author Sismo
 * @notice This attester is part of the family of the Hydra-S1 Attesters.
 * Hydra-S1 attesters enable users to prove they have an account in a group in a privacy preserving way.
 * The Hydra-S1 Base abstract contract is inherited and holds the complex Hydra S1 verification logic.
 * We invite readers to refer to:
 *    - https://hydra-s1.docs.sismo.io for a full guide through the Hydra-S1 ZK Attestations
 *    - https://hydra-s1-circuits.docs.sismo.io for circuits, prover and verifiers of Hydra-S1

 * This specific attester has the following characteristics:

 * - Zero Knowledge
 *   One cannot deduct from an attestation what source account was used to generate the underlying proof

 * - Non Strict (scores)
 *   If a user can generate an attestation of max value 100, they can also generate any attestation with value < 100.
 *   This attester generate attestations of scores

 * - Ticketed
 *   Each source account gets one userTicket per claim (i.e only one attestation per source account per claim)
 *   For people used to semaphore/ tornado cash people:
 *   userTicket = hash(sourceSecret, ticketIdentifier) <=> nullifierHash = hash(IdNullifier, externalNullifier)
 
 * - SoulBound (with cooldown period)
 *   A user can chose to delete attestations or generate attestation to a new destination.
 *   When deleting/ sending to a new destination, the ticket will enter a cooldown period, so it remains occasional
 *   User will need to wait until the end of the cooldown period before being able to delete or switch destination again
 *   One can however know that the former and the new destinations were created using the same userTicket
 
 * - Renewable
 *   A userTicket can actually be reused as long as the destination of the attestation remains the same
 *   It enables users to renew or update their attestations
 **/
contract HydraS1SoulboundAttester is IHydraS1SoulboundAttester, HydraS1Base, Attester {
  using HydraS1Lib for HydraS1ProofData;
  using HydraS1Lib for bytes;
  using HydraS1Lib for Request;

  // The deployed contract will need to be authorized to write into the Attestation registry
  // It should get write access on collections from AUTHORIZED_COLLECTION_ID_FIRST to AUTHORIZED_COLLECTION_ID_LAST.
  uint256 public immutable AUTHORIZED_COLLECTION_ID_FIRST;
  uint256 public immutable AUTHORIZED_COLLECTION_ID_LAST;
  uint256 public immutable SOULBOUND_COOLDOWN_DURATION;

  mapping(uint256 => TicketData) internal _userTicketsData;

  /*******************************************************
    INITIALIZATION FUNCTIONS                           
  *******************************************************/
  /**
   * @dev Constructor. Initializes the contract
   * @param attestationRegistryAddress Attestations Registry contract on which the attester will write attestations
   * @param hydraS1VerifierAddress ZK Snark Hydra-S1 Verifier contract
   * @param availableRootsRegistryAddress Registry storing the available groups for this attester (e.g roots of world merkle trees)
   * @param commitmentMapperAddress commitment mapper's public key registry
   * @param collectionIdFirst Id of the first collection in which the attester is supposed to record
   * @param collectionIdLast Id of the last collection in which the attester is supposed to record
   */
  constructor(
    address attestationRegistryAddress,
    address hydraS1VerifierAddress,
    address availableRootsRegistryAddress,
    address commitmentMapperAddress,
    uint256 collectionIdFirst,
    uint256 collectionIdLast,
    uint256 soulboundCooldownDuration
  )
    Attester(attestationRegistryAddress)
    HydraS1Base(hydraS1VerifierAddress, availableRootsRegistryAddress, commitmentMapperAddress)
  {
    AUTHORIZED_COLLECTION_ID_FIRST = collectionIdFirst;
    AUTHORIZED_COLLECTION_ID_LAST = collectionIdLast;
    SOULBOUND_COOLDOWN_DURATION = soulboundCooldownDuration;
  }

  /*******************************************************
    MANDATORY FUNCTIONS TO OVERRIDE FROM ATTESTER.SOL
  *******************************************************/

  /**
   * @dev Throws if user attestation request is invalid
   * Look into HydraS1Base for more details
   * @param request users request. Claim of having an account part of a group of accounts
   * @param data snark proof backing the claim
   */
  function _verifyRequest(Request calldata request, bytes calldata data) internal virtual override {
    HydraS1ProofData memory snarkProof = abi.decode(data, (HydraS1ProofData));
    HydraS1ProofInput memory snarkInput = snarkProof._input();
    HydraS1Claim memory claim = request._claim();

    // verifies that the proof corresponds to the claim
    _validateInput(claim, snarkInput);
    // verifies the proof validity
    _verifyProof(snarkProof);
  }

  /**
   * @dev Throws if user attestation deletion request is not made by its owner
   * @param attestation attestation to delete
   */
  function _verifyAttestationDeletionRequest(Attestation memory attestation, bytes calldata)
    internal
    view
    override
  {
    uint256 userTicket = abi.decode(attestation.extraData, (uint256));
    if (_userTicketsData[userTicket].destination != msg.sender)
      revert NotAttestationOwner(userTicket, msg.sender);
  }

  /**
   * @dev Returns the actual attestation constructed from the user request
   * @param request users request. Claim of having an account part of a group of accounts
   * @param data snark public input as well as snark proof
   */
  function constructAttestation(Request calldata request, bytes calldata data)
    public
    view
    virtual
    override(IAttester, Attester)
    returns (Attestation memory)
  {
    HydraS1Claim memory claim = request._claim();
    uint256 attestationCollectionId = AUTHORIZED_COLLECTION_ID_FIRST + claim.groupId;
    if (attestationCollectionId > AUTHORIZED_COLLECTION_ID_LAST)
      revert CollectionIdOutOfBound(attestationCollectionId);

    // The issuer of the attestation is the attester
    address issuer = address(this);
    // user sends the ticket as input in the data
    uint256 userTicket = data._getTicket();

    return (
      Attestation(
        attestationCollectionId,
        request.destination,
        issuer,
        claim.claimedValue,
        claim.groupProperties.generationTimestamp,
        abi.encode(userTicket)
      )
    );
  }

  /*******************************************************
    OPTIONAL HOOK VIRTUAL FUNCTIONS FROM ATTESTER.SOL
  *******************************************************/
  /**
   * @dev Hook run before recording the attestation.
   * Throws if ticket already used, not a renewal, and ticket on cooldown.
   * @param request users request. Claim of having an account part of a group of accounts
   * @param data provided to back the request. snark input and snark proof
   */
  function _beforeRecordAttestation(
    Request calldata request,
    Attestation memory,
    bytes calldata data
  ) internal virtual override {
    uint256 userTicket = data._getTicket();
    TicketData memory userTicketData = _userTicketsData[userTicket];

    if (
      userTicketData.destination != address(0) && userTicketData.destination != request.destination
    ) {
      if (_isOnCooldown(userTicketData)) revert TicketUsedAndOnCooldown(userTicketData);
      _setTicketOnCooldown(userTicket);
    }
    _setDestinationForTicket(userTicket, request.destination);
  }

  function _beforeDeleteAttestation(Attestation memory attestation, bytes calldata data)
    internal
    override
  {
    // we retrieve the ticketUsed from the attestation extraData
    uint256 userTicket = abi.decode(attestation.extraData, (uint256));
    if (_isOnCooldown(_userTicketsData[userTicket]) == true) revert TicketFrozen(userTicket);
    _userTicketsData[userTicket].destination = address(0);
  }

  /*******************************************************
    Hydra-S1 MANDATORY FUNCTIONS FROM Hydra-S1 Base Attester
  *******************************************************/

  /**
   * @dev Returns the ticket identifier from a user claim
   * @param claim user Hydra-S1 claim = have an account with a specific value in a specific group
   * ticket = hash(sourceSecretHash, ticketIdentifier), which is verified inside the snark
   * users bring sourceSecretHash as private input in snark which guarantees privacy
   
   * Here we chose ticketIdentifier = hash(attesterAddress, claim.GroupId)
   * Creates one ticket per group, per user and makes sure no collision with other attester's tickets
  **/
  function _getTicketIdentifierOfClaim(HydraS1Claim memory claim)
    internal
    view
    override
    returns (uint256)
  {
    uint256 ticketIdentifier = _encodeInSnarkField(address(this), claim.groupId);
    return ticketIdentifier;
  }

  /*******************************************************
    Hydra-S1 Attester Specific Functions
  *******************************************************/

  /**
   * @dev Getter, returns the last attestation destination of a ticket
   * @param userTicket ticket used
   **/
  function getDestinationOfTicket(uint256 userTicket) external view override returns (address) {
    return _getDestinationOfTicket(userTicket);
  }

  /**
   * @dev Getter, returns the data linked to a ticket
   * @param userTicket ticket used
   **/
  function getTicketData(uint256 userTicket) external view override returns (TicketData memory) {
    return _getTicketData(userTicket);
  }

  /**
   * @dev returns whether a ticket is on cooldown or not
   * @param userTicket ticket used
   **/
  function isTicketOnCooldown(uint256 userTicket) external view override returns (bool) {
    return _isOnCooldown(_getTicketData(userTicket));
  }

  function _setDestinationForTicket(uint256 userTicket, address destination) internal virtual {
    _userTicketsData[userTicket].destination = destination;
    emit TicketDestinationUpdated(userTicket, destination);
  }

  function _setTicketOnCooldown(uint256 userTicket) internal {
    _userTicketsData[userTicket].cooldownStart = uint32(block.timestamp);
    emit TicketSetOnCooldown(userTicket);
  }

  function _getDestinationOfTicket(uint256 userTicket) internal view returns (address) {
    return _userTicketsData[userTicket].destination;
  }

  function _isOnCooldown(TicketData memory userTicketData) internal view returns (bool) {
    return userTicketData.cooldownStart + SOULBOUND_COOLDOWN_DURATION < block.timestamp;
  }

  function _getTicketData(uint256 userTicket) internal view returns (TicketData memory) {
    return _userTicketsData[userTicket];
  }

  function _encodeInSnarkField(address addr, uint256 nb) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(addr, nb))) % HydraS1Lib.SNARK_FIELD;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import {IAttester} from './interfaces/IAttester.sol';
import {IAttestationsRegistry} from './interfaces/IAttestationsRegistry.sol';
import {Request, Attestation, AttestationData} from './libs/Structs.sol';

/**
 * @title Attester Abstract Contract
 * @author Sismo
 * @notice Contract to be inherited by Attesters
 * All attesters that expect to be authorized in Sismo Protocol (i.e write access on the registry)
 * are recommended to implemented this abstract contract

 * Take a look at the HydraS1SimpleAttester.sol for example on how to implement this abstract contract
 *
 * This contracts is built around two main external standard functions.
 * They must NOT be override them, unless your really know what you are doing
 
 * - generateAttestation(request, proof) => will write an attestation in the registry
 * 1. (MANDATORY) Implement the constructAttestation() view function which generate the attestation from user request
 * 2. (MANDATORY) Implement teh _verifyRequest() internal function where to write checks
 * 3. (OPTIONAL)  Override _beforeRecordAttestation and _afterRecordAttestation hooks

 * - deleteAttestation(collectionId, owner, proof) => will delete an attestation in the registry
 * 1. (DEFAULT)  By default this function throws (see _verifyAttestationDeletionRequest)
 * 2. (OPTIONAL) Override the _verifyAttestationDeletionRequest so it no longer throws
 * 3. (OPTIONAL) Override _beforeDeleteAttestation and _afterDeleteAttestation hooks

 * For more information: https://attesters.docs.sismo.io
 **/
abstract contract Attester is IAttester {
  // Registry where all attestations are stored
  IAttestationsRegistry internal immutable ATTESTATIONS_REGISTRY;

  /**
   * @dev Constructor
   * @param attestationsRegistryAddress The address of the AttestationsRegistry contract storing attestations
   */
  constructor(address attestationsRegistryAddress) {
    ATTESTATIONS_REGISTRY = IAttestationsRegistry(attestationsRegistryAddress);
  }

  /**
   * @dev Main external function. Allows to generate an attestation by making a request and submitting proof
   * @param request User request
   * @param data Data sent along the request to prove its validity
   * @return attestation The attestation that has been recorded
   */
  function generateAttestation(Request calldata request, bytes calldata data)
    external
    override
    returns (Attestation memory)
  {
    // Verify if request is valid by verifying against proof
    _verifyRequest(request, data);

    // Generate the actual attestation from user request
    Attestation memory attestation = constructAttestation(request, data);

    _beforeRecordAttestation(request, attestation, data);

    ATTESTATIONS_REGISTRY.recordAttestation(attestation);

    emit AttestationGenerated(attestation);

    return attestation;
  }

  /**
   * @dev External facing function. Allows to delete an attestation by submitting proof
   * @param collectionId Collection identifier of the attestation to delete
   * @param attestationOwner Owner of the attestation to delete
   * @param data Data sent along the deletion request to prove its validity
   * @return attestation The attestation that was deleted
   */
  function deleteAttestation(
    uint256 collectionId,
    address attestationOwner,
    bytes calldata data
  ) external override returns (Attestation memory) {
    // fetch attestation from the registry
    (
      address issuer,
      uint256 attestationValue,
      uint32 timestamp,
      bytes memory extraData
    ) = ATTESTATIONS_REGISTRY.getAttestationDataTuple(collectionId, attestationOwner);

    Attestation memory attestation = Attestation(
      collectionId,
      attestationOwner,
      issuer,
      attestationValue,
      timestamp,
      extraData
    );

    _verifyAttestationDeletionRequest(attestation, data);

    _beforeDeleteAttestation(attestation, data);

    ATTESTATIONS_REGISTRY.deleteAttestation(attestation);

    _afterDeleteAttestation(attestation, data);

    emit AttestationDeleted(attestation);

    return attestation;
  }

  /**
   * @dev MANDATORY: must be implemented in attesters
   * It should construct the attestation from the user request and the proof
   * @param request User request
   * @param data Data sent along the request to prove its validity
   * @return attestation The attestation that will be recorded
   */
  function constructAttestation(Request calldata request, bytes calldata data)
    public
    virtual
    returns (Attestation memory);

  /**
   * @dev Attestation registry getter
   * @return attestationRegistry
   */
  function getAttestationRegistry() external view override returns (IAttestationsRegistry) {
    return ATTESTATIONS_REGISTRY;
  }

  /**
   * @dev MANDATORY: must be implemented in attesters
   * It should verify the user request is valid
   * @param request User request
   * @param data Data sent along the request to prove its validity
   */
  function _verifyRequest(Request calldata request, bytes calldata data) internal virtual;

  /**
   * @dev Optional: must be overridden by attesters that want to feature attestation deletion
   * Default behavior: throws
   * It should verify the attestation deletion request is valid
   * @param attestation Attestation that will be deleted
   * @param data Data sent along the request to prove its validity
   */
  function _verifyAttestationDeletionRequest(Attestation memory attestation, bytes calldata data)
    internal
    virtual
  {
    revert AttestationDeletionNotImplemented();
  }

  /**
   * @dev Optional: Hook, can be overridden in attesters
   * Will be called before recording the attestation in the registry
   * @param request User request
   * @param data Data sent along the request to prove its validity
   */
  function _beforeRecordAttestation(
    Request calldata request,
    Attestation memory attestation,
    bytes calldata data
  ) internal virtual {}

  /**
   * @dev (Optional) Can be overridden in attesters inheriting this contract
   * Will be called after recording an attestation
   * @param request User request
   * @param data Data sent along the request to prove its validity
   */
  function _afterRecordAttestation(
    Request calldata request,
    Attestation memory attestation,
    bytes calldata data
  ) internal virtual {}

  /**
   * @dev Optional: Hook, can be overridden in attesters
   * Will be called before deleting the attestation from the registry
   * @param attestation Attestation to delete
   * @param data Data sent along the deletion request to prove its validity
   */
  function _beforeDeleteAttestation(Attestation memory attestation, bytes calldata data)
    internal
    virtual
  {}

  /**
   * @dev Optional: Hook, can be overridden in attesters
   * Will be called after deleting the attestation from the registry
   * @param attestation Attestation to delete
   * @param data Data sent along the deletion request to prove its validity
   */
  function _afterDeleteAttestation(Attestation memory attestation, bytes calldata data)
    internal
    virtual
  {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Attestation, AttestationData} from '../libs/Structs.sol';

/**
 * @title IAttestationsRegistry
 * @author Sismo
 * @notice This is the interface of the AttestationRegistry
 */
interface IAttestationsRegistry {
  event AttestationRecorded(Attestation attestation);
  event AttestationDeleted(Attestation attestation);

  /**
   * @dev Main function to be called by authorized issuers
   * @param attestation The attestation to be recorded (creates a new one or overrides an existing one)
   */
  function recordAttestation(Attestation calldata attestation) external;

  /**
   * @dev Delete function to be called by authorized issuers
   * @param attestation The attestation to be deleted
   */
  function deleteAttestation(Attestation calldata attestation) external;

  /**
   * @dev Returns whether a user has an attestation from a collection
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function hasAttestation(uint256 collectionId, address owner) external returns (bool);

  /**
   * @dev Getter of the data of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationData(uint256 collectionId, address owner)
    external
    view
    returns (AttestationData memory);

  /**
   * @dev Getter of the value of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationValue(uint256 collectionId, address owner) external view returns (uint256);

  /**
   * @dev Getter of the data of a specific attestation as tuple
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationDataTuple(uint256 collectionId, address owner)
    external
    view
    returns (
      address,
      uint256,
      uint32,
      bytes memory
    );

  /**
   * @dev Getter of the extraData of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationExtraData(uint256 collectionId, address owner)
    external
    view
    returns (bytes memory);

  /**
   * @dev Getter of the issuer of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationIssuer(uint256 collectionId, address owner)
    external
    view
    returns (address);

  /**
   * @dev Getter of the timestamp of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationTimestamp(uint256 collectionId, address owner)
    external
    view
    returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Request, Attestation} from '../libs/Structs.sol';
import {IAttestationsRegistry} from '../interfaces/IAttestationsRegistry.sol';

/**
 * @title IAttester
 * @author Sismo
 * @notice This is the interface for the attesters in Sismo Protocol
 */
interface IAttester {
  event AttestationGenerated(Attestation attestation);

  event AttestationDeleted(Attestation attestation);

  error AttestationDeletionNotImplemented();

  /**
   * @dev Main external function. Allows to generate an attestation by making a request and submitting proof
   * @param request User request
   * @param data Data sent along the request to prove its validity
   * @return attestation The attestation that has been recorded
   */
  function generateAttestation(Request calldata request, bytes calldata data)
    external
    returns (Attestation memory);

  /**
   * @dev External facing function. Allows to delete an attestation by submitting proof
   * @param collectionId Collection identifier of the attestation to delete
   * @param attestationOwner Owner of the attestation to delete
   * @param data Data sent along the deletion request to prove its validity
   * @return attestation The attestation that was deleted
   */
  function deleteAttestation(
    uint256 collectionId,
    address attestationOwner,
    bytes calldata data
  ) external returns (Attestation memory);

  /**
   * @dev MANDATORY: must be implemented in attesters
   * It should construct the attestation from the user request and the proof
   * @param request User request
   * @param data Data sent along the request to prove its validity
   * @return attestation The attestation that will be recorded
   */
  function constructAttestation(Request calldata request, bytes calldata data)
    external
    returns (Attestation memory);

  /**
   * @dev Attestation registry address getter
   * @return attestationRegistry Address of the registry
   */
  function getAttestationRegistry() external view returns (IAttestationsRegistry);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
 * @title  Attestations Registry State
 * @author Sismo
 * @notice This contract holds all of the storage variables and data
 *         structures used by the AttestationsRegistry and parent
 *         contracts.
 */

// User Attestation Request, can be made by any user
// The context of an Attestation Request is a specific attester contract
// Each attester has groups of accounts in its available data
// eg: for a specific attester:
//     group 1 <=> accounts that sent txs on mainnet
//     group 2 <=> accounts that sent txs on polygon
// eg: for another attester:
//     group 1 <=> accounts that sent eth txs in 2022
//     group 2 <=> accounts sent eth txs in 2021
struct Request {
  // implicit address attester;
  // implicit uint256 chainId;
  Claim[] claims;
  address destination; // destination that will receive the end attestation
}

struct Claim {
  uint256 groupId; // user claims to have an account in this group
  uint256 claimedValue; // user claims this value for its account in the group
  bytes extraData; // arbitrary data, may be required by the attester to verify claims or generate a specific attestation
}

/**
 * @dev Attestation Struct. This is the struct receive as argument by the Attestation Registry.
 * @param collectionId Attestation collection
 * @param owner Attestation collection
 * @param issuer Attestation collection
 * @param value Attestation collection
 * @param timestamp Attestation collection
 * @param extraData Attestation collection
 */
struct Attestation {
  // implicit uint256 chainId;
  uint256 collectionId; // Id of the attestation collection (in the registry)
  address owner; // Owner of the attestation
  address issuer; // Contract that created or last updated the record.
  uint256 value; // Value of the attestation
  uint32 timestamp; // Timestamp chosen by the attester, should correspond to the effective date of the attestation
  // it is different from the recording timestamp (date when the attestation was recorded)
  // e.g a proof of NFT ownership may have be recorded today which is 2 month old data.
  bytes extraData; // arbitrary data that can be added by the attester
}

// Attestation Data, stored in the registry
// The context is a specific owner of a specific collection
struct AttestationData {
  // implicit uint256 chainId
  // implicit uint256 collectionId - from context
  // implicit owner
  address issuer; // Address of the contract that recorded the attestation
  uint256 value; // Value of the attestation
  uint32 timestamp; // Effective date of issuance of the attestation. (can be different from the recording timestamp)
  bytes extraData; // arbitrary data that can be added by the attester
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IAvailableRootsRegistry} from './interfaces/IAvailableRootsRegistry.sol';
import {Initializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';

/**
 * @title Attesters Groups Registry
 * @author Sismo
 * @notice This contract stores that data required by attesters to be available so they can verify user claims
 * This contract is deployed behind a proxy and this implementation is focused on storing merkle roots
 * For more information: https://available-roots-registry.docs.sismo.io
 *
 **/
contract AvailableRootsRegistry is IAvailableRootsRegistry, Initializable, Ownable {
  mapping(address => mapping(uint256 => bool)) public _roots;

  /**
   * @dev Constructor
   * @param owner Owner of the contract, can register/ unregister roots
   */
  constructor(address owner) {
    initialize(owner);
  }

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param owner Owner of the contract, can update public key and address
   */
  function initialize(address owner) public initializer {
    _transferOwnership(owner);
  }

  /**
   * @dev Register a root available for an attester
   * @param attester Attester which will have the root available
   * @param root Root to register
   */
  function registerRootForAttester(address attester, uint256 root) external onlyOwner {
    if (attester == address(0)) revert CannotRegisterForZeroAddress();
    _registerRootForAttester(attester, root);
  }

  /**
   * @dev Unregister a root for an attester
   * @param attester Attester which will no longer have the root available
   * @param root Root to unregister
   */
  function unregisterRootForAttester(address attester, uint256 root) external onlyOwner {
    if (attester == address(0)) revert CannotUnregisterForZeroAddress();
    _unregisterRootForAttester(attester, root);
  }

  /**
   * @dev Registers a root, available for all contracts
   * @param root Root to register
   */
  function registerRootForAll(uint256 root) external onlyOwner {
    _registerRootForAttester(address(0), root);
  }

  /**
   * @dev Unregister a root, available for all contracts
   * @param root Root to unregister
   */
  function unregisterRootForAll(uint256 root) external onlyOwner {
    _unregisterRootForAttester(address(0), root);
  }

  /**
   * @dev returns whether a root is available for a caller (msg.sender)
   * @param root root to check whether it is registered for me or not
   */
  function isRootAvailableForMe(uint256 root) external view returns (bool) {
    return _roots[_msgSender()][root] || _roots[address(0)][root];
  }

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param attester Owner of the contract, can update public key and address
   * @param root Owner of the contract, can update public key and address
   */
  function isRootAvailableForAttester(address attester, uint256 root) external view returns (bool) {
    return _roots[attester][root] || _roots[address(0)][root];
  }

  function _registerRootForAttester(address attester, uint256 root) internal {
    _roots[attester][root] = true;
    if (attester == address(0)) {
      emit RegisteredRootForAll(root);
    } else {
      emit RegisteredRootForAttester(attester, root);
    }
  }

  function _unregisterRootForAttester(address attester, uint256 root) internal {
    _roots[attester][root] = false;
    if (attester == address(0)) {
      emit UnregisteredRootForAll(root);
    } else {
      emit UnregisteredRootForAttester(attester, root);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Initializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import {ICommitmentMapperRegistry} from './interfaces/ICommitmentMapperRegistry.sol';

/**
 * @title Commitment Mapper Registry Contract
 * @author Sismo
 * @notice This contract stores information about the commitment mapper.
 * Its ethereum address and its EdDSA public key
 * For more information: https://commitment-mapper.docs.sismo.io
 *
 **/
contract CommitmentMapperRegistry is ICommitmentMapperRegistry, Initializable, Ownable {
  uint256[2] internal _commitmentMapperPubKey;
  address _commitmentMapperAddress;

  /**
   * @dev Constructor
   * @param owner Owner of the contract, can update public key and address
   * @param commitmentMapperEdDSAPubKey EdDSA public key of the commitment mapper
   * @param commitmentMapperAddress Address of the commitment mapper
   */
  constructor(
    address owner,
    uint256[2] memory commitmentMapperEdDSAPubKey,
    address commitmentMapperAddress
  ) {
    initialize(owner, commitmentMapperEdDSAPubKey, commitmentMapperAddress);
  }

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param owner Owner of the contract, can update public key and address
   * @param commitmentMapperEdDSAPubKey EdDSA public key of the commitment mapper
   * @param commitmentMapperAddress Address of the commitment mapper
   */
  function initialize(
    address owner,
    uint256[2] memory commitmentMapperEdDSAPubKey,
    address commitmentMapperAddress
  ) public initializer {
    _transferOwnership(owner);
    _updateCommitmentMapperEdDSAPubKey(commitmentMapperEdDSAPubKey);
    _updateCommitmentMapperAddress(commitmentMapperAddress);
  }

  /**
   * @dev Updates the EdDSA public key
   * @param newEdDSAPubKey new EdDSA pubic key
   */
  function updateCommitmentMapperEdDSAPubKey(uint256[2] memory newEdDSAPubKey) external onlyOwner {
    _updateCommitmentMapperEdDSAPubKey(newEdDSAPubKey);
  }

  /**
   * @dev Updates the address
   * @param newAddress new address
   */
  function updateCommitmentMapperAddress(address newAddress) external onlyOwner {
    _updateCommitmentMapperAddress(newAddress);
  }

  /**
   * @dev Getter of the EdDSA public key of the commitment mapper
   */
  function getEdDSAPubKey() external view override returns (uint256[2] memory) {
    return _commitmentMapperPubKey;
  }

  /**
   * @dev Getter of the address of the commitment mapper
   */
  function getAddress() external view override returns (address) {
    return _commitmentMapperAddress;
  }

  function _updateCommitmentMapperAddress(address newAddress) internal {
    _commitmentMapperAddress = newAddress;
    emit UpdatedCommitmentMapperAddress(newAddress);
  }

  function _updateCommitmentMapperEdDSAPubKey(uint256[2] memory pubKey) internal {
    _commitmentMapperPubKey = pubKey;
    emit UpdatedCommitmentMapperEdDSAPubKey(pubKey);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/**
 * @title IAvailableRootsRegistry
 * @author Sismo
 * @notice Interface for (Merkle) Roots Registry
 */
interface IAvailableRootsRegistry {
  event RegisteredRootForAttester(address attester, uint256 root);
  event RegisteredRootForAll(uint256 root);
  event UnregisteredRootForAttester(address attester, uint256 root);
  event UnregisteredRootForAll(uint256 root);

  error CannotRegisterForZeroAddress();
  error CannotUnregisterForZeroAddress();

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param owner Owner of the contract, can update public key and address
   */
  function initialize(address owner) external;

  /**
   * @dev Register a root available for an attester
   * @param attester Attester which will have the root available
   * @param root Root to register
   */
  function registerRootForAttester(address attester, uint256 root) external;

  /**
   * @dev Unregister a root for an attester
   * @param attester Attester which will no longer have the root available
   * @param root Root to unregister
   */
  function unregisterRootForAttester(address attester, uint256 root) external;

  /**
   * @dev Registers a root, available for all contracts
   * @param root Root to register
   */
  function registerRootForAll(uint256 root) external;

  /**
   * @dev Unregister a root, available for all contracts
   * @param root Root to unregister
   */
  function unregisterRootForAll(uint256 root) external;

  /**
   * @dev returns whether a root is available for a caller (msg.sender)
   * @param root root to check whether it is registered for me or not
   */
  function isRootAvailableForMe(uint256 root) external view returns (bool);

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param attester Owner of the contract, can update public key and address
   * @param root Owner of the contract, can update public key and address
   */
  function isRootAvailableForAttester(address attester, uint256 root) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ICommitmentMapperRegistry {
  event UpdatedCommitmentMapperEdDSAPubKey(uint256[2] newEdDSAPubKey);
  event UpdatedCommitmentMapperAddress(address newAddress);
  error PubKeyNotValid(uint256[2] pubKey);

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param owner Owner of the contract, can update public key and address
   * @param commitmentMapperEdDSAPubKey EdDSA public key of the commitment mapper
   * @param commitmentMapperAddress Address of the commitment mapper
   */
  function initialize(
    address owner,
    uint256[2] memory commitmentMapperEdDSAPubKey,
    address commitmentMapperAddress
  ) external;

  /**
   * @dev Updates the EdDSA public key
   * @param newEdDSAPubKey new EdDSA pubic key
   */
  function updateCommitmentMapperEdDSAPubKey(uint256[2] memory newEdDSAPubKey) external;

  /**
   * @dev Updates the address
   * @param newAddress new address
   */
  function updateCommitmentMapperAddress(address newAddress) external;

  /**
   * @dev Getter of the address of the commitment mapper
   */
  function getEdDSAPubKey() external view returns (uint256[2] memory);

  /**
   * @dev Getter of the address of the commitment mapper
   */
  function getAddress() external view returns (address);
}