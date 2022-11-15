// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/**
 * @title OracleSolver
 * @dev Given two tokens it solves address of the chainlink oracle
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract OracleSolver {
  mapping(bytes32 => address) public tokensToSolver; //this should be private
  address[] public solvers;

  function addContract(
    address tokenA,
    address tokenB,
    address solver
  ) public {
    require(tokenA != tokenB, "OracleSolver: IDENTICAL_ADDRESSES");
    require(getContract(tokenA, tokenB) != address(0), "OractleSolver: PAIR_EXISTS");
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "OracleSolver: ZERO_ADDRESS");
    bytes32 tokens = keccak256(abi.encodePacked(token0, token1));
    tokensToSolver[tokens] = solver;
    solvers.push(solver);
  }

  function getContract(address tokenA, address tokenB) public view returns (address) {
    require(tokenA != tokenB, "OracleSolver: IDENTICAL_ADDRESSES");
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    bytes32 tokens = keccak256(abi.encodePacked(token0, token1));
    return tokensToSolver[tokens];
  }
}