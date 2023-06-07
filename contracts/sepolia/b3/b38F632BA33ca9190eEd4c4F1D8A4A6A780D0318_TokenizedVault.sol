//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Import the necessary files and lib
import "./IERC4626.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

// create your contract and inherit the your imports
contract TokenizedVault is IERC4626, ERC20 {
    // create an event that will the withdraw and deposit function
    event Deposit(address caller, uint256 amt);
    event Withdraw(
        address caller,
        address receiver,
        uint256 amt,
        uint256 shares
    );

    // create your variables and immutables
    ERC20 public immutable asset;

    //Defining structure
    struct shareHolderStruct {
        //Declaring different
        // structure elements
        uint depositeTime;
        uint256 assets;
    }

    // a mapping that checks if a user has deposited
    mapping(address => shareHolderStruct) shareHolder;

    // mapping(address => uint) depositeTime;

    constructor(
        ERC20 _underlying,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, 18) {
        asset = _underlying;
    }

    // a deposit function that receives assets from users
    function deposit(uint256 assets) public {
        // checks that the deposit is higher than 0
        require(assets > 0, "Deposit less than Zero");

        asset.transferFrom(msg.sender, address(this), assets);
        // checks the value of assets the holder has
        shareHolder[msg.sender].assets += assets;
        shareHolder[msg.sender].depositeTime = block.timestamp;
        // mints the reciept(shares)
        _mint(msg.sender, assets);

        emit Deposit(msg.sender, assets);
    }

    // returns total number of assets
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function getMinutes(uint timestamp) public pure returns (uint) {
        return uint(timestamp / 60 seconds);
    }

    function getMinutesSecondVariat(uint timestamp) public pure returns (uint) {
        return uint((timestamp / 60 seconds) % 60);
    }

    function getPassedAmountOfMinutes(
        uint depositeTime
    ) public view returns (uint) {
        return getMinutes(block.timestamp - depositeTime);
    }

    function calculateRewardPerRangeOfTime(
        uint depositeTime,
        uint256 shares
    ) public view returns (uint256 reward) {
        uint passedMinutes = getPassedAmountOfMinutes(depositeTime);
        return (shares * passedMinutes) / 1000;
    }

    function getPublicInfoAboutDepositHolder(
        address _address
    ) public view returns (shareHolderStruct memory) {
        return shareHolder[_address];
    }

    // users to return shares and get thier token back before they can withdraw, and requiers that the user has a deposit
    function redeem(
        uint256 shares,
        address receiver
    ) internal returns (uint256 assets) {
        require(shareHolder[msg.sender].assets > 0, "Not a share holder");
        shareHolder[msg.sender].assets -= shares;

        uint256 per = calculateRewardPerRangeOfTime(
            shareHolder[msg.sender].depositeTime,
            shareHolder[msg.sender].assets
        );

        _burn(msg.sender, shares);

        assets = shares + per;

        emit Withdraw(msg.sender, receiver, assets, per);
        return assets;
    }

    // allow msg.sender to withdraw his deposit plus interest

    function withdraw(uint256 shares, address receiver) public {
        uint256 payout = redeem(shares, receiver);
        asset.transfer(receiver, payout);
    }
}