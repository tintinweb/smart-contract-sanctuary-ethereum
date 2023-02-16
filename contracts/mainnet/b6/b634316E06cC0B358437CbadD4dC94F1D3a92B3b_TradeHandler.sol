// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import "./VM.sol";
import "./TradeHandlerHelper.sol";

/**
@title Trade Handler
@author yearn.finance
@notice TradeHandler is in charge of tracking which strategy wants to do certain
trade. The strategy registers what they have and what they want and wait for an
async trade. TradeHandler trades are executed by mechs through a weiroll VM.
*/

contract TradeHandler is VM {
    address payable public governance;
    address payable public pendingGovernance;

    // Treasury multisig for sweeps
    address payable public treasury;

    // COW protocol settlement contract address.
    address public settlement;

    // Mechs are addresses other than `settlement` that are authorized to
    // to call `execute()`
    mapping(address => bool) public mechs;

    // Solvers are EOAs authorised by COW protocol's settlement contract to
    // settle batches won at an auction
    mapping(address => bool) public solvers;

    event UpdatedSettlement(address settlement);

    event UpdatedTreasury(address treasury);

    event UpdatedGovernance(address governance);

    event AddedMech(address mech);
    event RemovedMech(address mech);

    event AddedSolver(address solver);
    event RemovedSolver(address solver);

    event TradeEnabled(
        address indexed seller,
        address indexed tokenIn,
        address indexed tokenOut
    );
    event TradeDisabled(
        address indexed seller,
        address indexed tokenIn,
        address indexed tokenOut
    );

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    // The settlement contract must be authorized to call `execute()`, but additional
    // safeguards are needed because solvers other than Seasolver are also authorized
    // to call settlement.settle().
    modifier onlyAuthorized() {
        require(
            ((msg.sender == settlement) && solvers[tx.origin]) ||
                ((msg.sender != settlement && mechs[msg.sender])),
            "!authorized"
        );
        _;
    }

    constructor(address payable _governance) {
        governance = _governance;
        treasury = _governance;
        mechs[_governance] = true;
    }

    function setGovernance(address payable _governance)
        external
        onlyGovernance
    {
        pendingGovernance = _governance;
    }

    function setTreasury(address payable _treasury) external onlyGovernance {
        treasury = _treasury;
        emit UpdatedTreasury(_treasury);
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
        delete pendingGovernance;
        emit UpdatedGovernance(governance);
    }

    function setSettlement(address _settlement) external onlyGovernance {
        // Settlement can't be a mech.
        require(!mechs[_settlement]);
        settlement = _settlement;
        emit UpdatedSettlement(_settlement);
    }

    function addMech(address _mech) external onlyGovernance {
        // Settlement can't be set as mech as that would grant
        // other solvers power to execute.
        require(settlement != _mech);
        mechs[_mech] = true;
        emit AddedMech(_mech);
    }

    function removeMech(address _mech) external onlyGovernance {
        delete mechs[_mech];
        emit RemovedMech(_mech);
    }

    function addSolver(address _solver) external onlyGovernance {
        solvers[_solver] = true;
        emit AddedSolver(_solver);
    }

    function removeSolver(address _solver) external onlyGovernance {
        delete solvers[_solver];
        emit RemovedSolver(_solver);
    }

    function enable(address _tokenIn, address _tokenOut) external {
        require(_tokenIn != address(0));
        require(_tokenOut != address(0));

        emit TradeEnabled(msg.sender, _tokenIn, _tokenOut);
    }

    function disable(address _tokenIn, address _tokenOut) external {
        _disable(msg.sender, _tokenIn, _tokenOut);
    }

    function disableByAdmin(
        address _strategy,
        address _tokenIn,
        address _tokenOut
    ) external onlyGovernance {
        _disable(_strategy, _tokenIn, _tokenOut);
    }

    function _disable(
        address _strategy,
        address _tokenIn,
        address _tokenOut
    ) internal {
        emit TradeDisabled(_strategy, _tokenIn, _tokenOut);
    }

    function execute(bytes32[] calldata commands, bytes[] memory state)
        external
        onlyAuthorized
        returns (bytes[] memory)
    {
        return _execute(commands, state);
    }

    function sweep(address[] calldata _tokens, uint256[] calldata _amounts)
        external
    {
        uint256 _size = _tokens.length;
        require(_size == _amounts.length);

        for (uint256 i = 0; i < _size; i++) {
            if (_tokens[i] == address(0)) {
                // Native ETH
                TradeHandlerHelper.safeTransferETH(treasury, _amounts[i]);
            } else {
                // ERC20s
                TradeHandlerHelper.safeTransfer(
                    _tokens[i],
                    treasury,
                    _amounts[i]
                );
            }
        }
    }

    // `fallback` is called when msg.data is not empty
    fallback() external payable {}

    // `receive` is called when msg.data is empty
    receive() external payable {}
}