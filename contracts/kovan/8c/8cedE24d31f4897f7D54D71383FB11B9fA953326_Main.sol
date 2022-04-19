//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IBruFactory.sol";
import "./interfaces/IBruPool.sol";
import "./interfaces/IERC20.sol";

contract Main{
    address private factoryAddress;
    bytes32 INIT_CODE_HASH;

    constructor (address _address, bytes32 initCode){
        factoryAddress = _address;
        INIT_CODE_HASH = initCode;
    }
    function deposit(address tokenAddress, uint amount) external {
        if(IBruFactory(factoryAddress).getPool(tokenAddress) == address(0)){
            IBruFactory(factoryAddress).createPool(tokenAddress);
        }
        address poolAddress = IBruFactory(factoryAddress).getPool(tokenAddress);
        IBruPool(poolAddress).deposit(msg.sender,amount);

    }

    function withdraw(address tokenAddress, uint amount) external {
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= amount,"Balance atleast be equal to redeem  amount");
        address poolAddress = IBruFactory(factoryAddress).getPool(tokenAddress);
        IBruPool(poolAddress).withdraw(msg.sender,amount);
    }
    function poolFor(address tokenAddress) public view returns(address){
        bytes32 salt = keccak256(abi.encodePacked(tokenAddress));
        address poolAddress = Create2.computeAddress(salt, INIT_CODE_HASH,factoryAddress);
        return poolAddress;
    }
    
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
interface IBruPool{
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    function factory() external view returns (address);
    function token0() external view returns (address);


    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);

    function initialize(address) external;

    function deposit(address _address, uint amount) external;
    function withdraw(address _address, uint amount) external;

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

interface IBruFactory{
    event PoolCreated(address indexed tokenAddress, address indexed poolAddress);

    function getPool(address tokenAddress ) external view returns (address poolAddress);
    function allowToken(address tokenAddress) external;

    function createPool(address tokenAddress) external returns (address poolAddress);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}