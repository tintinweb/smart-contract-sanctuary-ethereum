// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Interfaces.sol";

contract Vanir {
  uint8 public constant decimals = 18; // Should probably not be smaller than wei (18), as we will lose data when converting msg.value

  uint8 constant weiDecimals = 18;
  uint8 constant wadDecimals = 18;
  uint8 constant rayDecimals = 27;
  uint8 constant radDecimals = 45;

  bytes32 private constant cdpManagerKey = "CDP_MANAGER";
  bytes32 private constant mcdVatKey = "MCD_VAT";
  bytes32 private constant mcdJoinDaiKey = "MCD_JOIN_DAI";
  bytes32 private constant mcdDaiTokenKey = "MCD_DAI";
  bytes32 private constant mcdJugKey = "MCD_JUG";
  bytes32 private constant wEthTokenKey = "ETH";

  struct Loan {
    bytes32 ilk;
    bytes32 joinKey;
    uint ink;
    uint art;
  }
  
  struct Ilk {
      uint256 Art;   // Total Normalised Debt     [wad]
      uint256 rate;  // Accumulated Rates         [ray]
      uint256 spot;  // Price with Safety Margin  [ray]
      uint256 line;  // Debt Ceiling              [rad]
      uint256 dust;  // Urn Debt Floor            [rad]
  }

  McdAddressProvider public mcdAddressProvider;

	mapping(address => uint256[]) public userLoans;
  mapping(address => mapping(uint256 => Loan)) public loans;

	address private owner;

  constructor(address mcdAddressProviderAddress) {
    mcdAddressProvider = McdAddressProvider(mcdAddressProviderAddress);
		owner = msg.sender;
  }

	receive() external payable {}

	function withdraw(uint256 amount) public {
		require(msg.sender == owner, "not allowed");
		payable(owner).transfer(amount);
	}

  error UintError(uint256);

  function openLoanETH(bytes32 ilkKey, bytes32 joinKey, uint daiAmount) public payable {
    McdCdpManager manager = McdCdpManager(mcdAddressProvider.getAddress(cdpManagerKey));
    McdJoin join = McdJoin(mcdAddressProvider.getAddress(joinKey));
    McdJoinDai joinDai = McdJoinDai(mcdAddressProvider.getAddress(mcdJoinDaiKey));
    McdJug jug = McdJug(mcdAddressProvider.getAddress(mcdJugKey));
    McdVat vat = McdVat(mcdAddressProvider.getAddress(mcdVatKey));
    WEthToken wEth = WEthToken(mcdAddressProvider.getAddress(wEthTokenKey));

    require(msg.value > 0, "vanir/value cannot be 0");
		require(daiAmount > 0, "vanir/daiAmount cannot be 0");

    //Wrap ETH
    wEth.deposit{value:msg.value}();
    
    // Update rate, so we don't have to pay unneccesary interest
    jug.drip(ilkKey);

    // Open vault
    manager.open(ilkKey, address(this));
    uint256 cdp = manager.last(address(this));

    // ink and art with internal decimals
    // ink is amount of collateral locked in
    // art is normalized debt, ie debt devided by current rate, so if you want x dai art should be x / rate
    (,uint256 rate,,,) = vat.ilks(ilkKey);
    uint256 ink = toPrecision(wEth.balanceOf(address(this)), wEth.decimals(), decimals);
    uint256 art = ((daiAmount * (10 ** rayDecimals)) / rate) + 1;
    
    // Transfer collateral to vault
    wEth.approve(address(join), toPrecision(msg.value, wadDecimals, wEth.decimals()));
    join.join(manager.urns(cdp), toPrecision(ink, decimals, join.dec()));

    // Lock in wEth and generate dai
    manager.frob(cdp, int(toPrecision(ink, decimals, wadDecimals)), int(toPrecision(art, decimals, wadDecimals)));
    
    // Move dai out of vault
    manager.move(cdp, address(this), toPrecision(daiAmount, decimals, radDecimals));
    vat.hope(address(joinDai));
    joinDai.exit(msg.sender, toPrecision(daiAmount, decimals, wadDecimals));

    // store loan info
		userLoans[msg.sender].push(cdp);
    loans[msg.sender][cdp] = Loan(ilkKey, joinKey, ink, art);
  }

	function last(address usr) public view returns (uint256) {
		return userLoans[usr][userLoans[usr].length - 1];
	}

	function closeLoanEth(address payable usr, uint256 cdp) public {
		Loan memory loan = loans[usr][cdp];
		require(loan.art > 0, "vanir/loan does not exist");
		require(loan.ink > 0, "vanir/loan does not exist");
		require(msg.sender == usr, "vanir/can only close own loan");

		// Get outstanding debt
		uint256 outstandingDebt = getOutstandingDebt(usr, cdp);

		// Make sure we have enough allowance
		DaiToken dai = DaiToken(mcdAddressProvider.getAddress(mcdDaiTokenKey));
		require(toPrecision(dai.allowance(usr, address(this)), dai.decimals(), decimals) >= outstandingDebt, "vanir/insufficient allowance");

		// Transfer dai to self
		dai.transferFrom(usr, address(this), outstandingDebt);

		// Transfer dai to vault
		McdJoinDai joinDai = McdJoinDai(mcdAddressProvider.getAddress(mcdJoinDaiKey));
		McdCdpManager manager = McdCdpManager(mcdAddressProvider.getAddress(cdpManagerKey));
		dai.approve(address(joinDai), outstandingDebt);
		joinDai.join(manager.urns(cdp), outstandingDebt);

		// Lock in dai and free up collateral
		manager.frob(cdp, -int256(toPrecision(loan.ink, decimals, wadDecimals)), -int256(toPrecision(loan.art, decimals, wadDecimals)));

		// Move collateral out of vault
		manager.flux(cdp, address(this), toPrecision(loan.ink, decimals, wadDecimals));
		McdJoin join = McdJoin(mcdAddressProvider.getAddress(loan.joinKey));
		join.exit(address(this), toPrecision(loan.ink, decimals, join.dec()));

		// Unwrap wEth and send back
    WEthToken wEth = WEthToken(mcdAddressProvider.getAddress(wEthTokenKey));
		wEth.withdraw(toPrecision(loan.ink, decimals, wEth.decimals()));
		usr.transfer(toPrecision(loan.ink, decimals, wadDecimals));

		// Clean up loan data
		delete loans[usr][cdp];

		// Remove loan from userLoans[usr]
		bool found = false;
		for(uint i = 0; i < userLoans[usr].length - 1; i++) {
			if(userLoans[usr][i] == cdp) {
				found = true;
			}

			if(found) {
				userLoans[usr][i] = userLoans[usr][i + 1];
			}
		}

		if(found) {
			userLoans[usr].pop();
		} else if (userLoans[usr][userLoans[usr].length - 1] == cdp) {
			userLoans[usr].pop();
		} else {
			revert("vanir/Could not find loan");
		}
	}

	function getOutstandingDebt(address usr, uint256 cdp) public view returns (uint256) {
		Loan memory loan = loans[usr][cdp];
		require(loan.art > 0, "vanir/loan does not exist");

		McdVat vat = McdVat(mcdAddressProvider.getAddress(mcdVatKey));
		(, uint256 rate, , , ) = vat.ilks(loan.ilk);

		uint256 outstanding = loan.art * rate;

		return toPrecision(outstanding, wadDecimals + rayDecimals, decimals) + 1;
	}

  function toPrecision(uint256 number, uint256 from, uint256 to) private pure returns(uint256) {
    if(from == to) {
      return number;
    }

    if(from > to) {
      return number / (10 ** (from - to));
    }

    if(to > from) {
      return number * (10 ** (to - from));
    }

    revert("vanir/inconsistent math");
  }
}