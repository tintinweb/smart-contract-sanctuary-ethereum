// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IFOInitializable.sol";

/**
 * @title IFODeployer
 */
contract IFODeployer is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    uint256 public constant MAX_BUFFER_BLOCKS = 1200000; // 600,000 blocks (6-7 days on Fantom)
    mapping(address => bool) private _ifoContracts;
    address[] private ifos;
    mapping(address => uint256) private userPoints;

    event UserPointIncrease(
        address indexed userAddress,
        uint256 numberPoints,
        uint256 indexed campaignId
    );
    event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);
    event NewIFOContract(address indexed ifoAddress);

    /**
     * @notice It creates the IFO contract and initializes the contract.
     * @param _lpToken: the LP token used
     * @param _offeringToken: the token that is offered for the IFO
     * @param _startBlock: the start block for the IFO
     * @param _endBlock: the end block for the IFO
     * @param _adminAddress: the admin address for handling tokens
     */
    function createIFO(
        address _lpToken,
        address _offeringToken,
        uint256 _startBlock,
        uint256 _endBlock,
        address _adminAddress,
        address _ifoPoolAddress,
        uint256[6] calldata _overflowCliff 
    ) external onlyOwner {
        require(IERC20(_lpToken).totalSupply() >= 0);
        require(IERC20(_offeringToken).totalSupply() >= 0);
        require(_lpToken != _offeringToken, "Operations: Tokens must be be different");
        require(_endBlock < (block.number + MAX_BUFFER_BLOCKS), "Operations: EndBlock too far");
        require(_startBlock < _endBlock, "Operations: StartBlock must be inferior to endBlock");
        require(_startBlock > block.number, "Operations: StartBlock must be greater than current block");
        require(_overflowCliff[0]>0 && 
                _overflowCliff[0]<_overflowCliff[1] &&
                _overflowCliff[1]<_overflowCliff[2] &&
                _overflowCliff[2]<_overflowCliff[3] && 
                _overflowCliff[3]<_overflowCliff[4] && 
                _overflowCliff[4]<_overflowCliff[5],
                "Operations: Cliffs must be Increasingly");

        bytes memory bytecode = type(IFOInitializable).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_lpToken, _offeringToken, _startBlock));
        address ifoAddress;

        assembly {
            ifoAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IFOInitializable(ifoAddress).initialize(
            _lpToken,
            _offeringToken,
            _startBlock,
            _endBlock,
            MAX_BUFFER_BLOCKS,
            _adminAddress,
            _ifoPoolAddress,
            _overflowCliff
        );

        _ifoContracts[ifoAddress] = true;
        ifos.push(ifoAddress);
        emit NewIFOContract(ifoAddress);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress) external onlyOwner {
        uint256 balanceToRecover = IERC20(_tokenAddress).balanceOf(address(this));
        require(balanceToRecover > 0, "Operations: Balance must be > 0");
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), balanceToRecover);
        emit AdminTokenRecovery(_tokenAddress, balanceToRecover);
    }



    function increaseUserPoints(
        address _userAddress,
        uint256 _numberPoints,
        uint256 _campaignId
    ) external {
        //Only IFO contracts can call this function
        require(_ifoContracts[msg.sender], "Not a point admin");
        // Increase the number of points for the user
        userPoints[_userAddress] = userPoints[_userAddress].add(_numberPoints);
        emit UserPointIncrease(_userAddress, _numberPoints, _campaignId);
        emit UserPointIncrease(_userAddress, _numberPoints, _campaignId);
    }

    function viewUserPoints(address _userAddress) public view returns(uint256){
        return userPoints[_userAddress];
    }

    function viewIfos(uint256 _index) public view returns(address){
        return ifos[_index];
    }
}