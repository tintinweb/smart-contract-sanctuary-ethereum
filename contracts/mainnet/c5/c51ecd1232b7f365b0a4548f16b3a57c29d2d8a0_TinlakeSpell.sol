/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

pragma solidity >=0.6.12;

// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

interface RootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface AuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
    function deny(address) external;
}

interface TrancheLike {
	function redeemOrder(address, uint) external;
	function authTransfer(address, address, uint256) external;
	function users(address) external returns (uint, uint, uint);
}

interface ERC20Like {
    function balanceOf(address) external returns(uint);
	function transfer(address, uint) external;
}

interface MemberListLike {
	function updateMember(address, uint) external;
	function hasMember(address) external returns (bool);
}

// spell to rescue funds from a CF4 redemption order made with a compromised address
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

	address public ROOT = address(0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6);
	address public TINLAKE_CURRENCY = address(0);
	address public TITLE = address(0);
	address public PILE = address(0);
	address public FEED = address(0);
	address public SHELF = address(0);
	address public JUNIOR_TRANCHE = address(0);
	address public JUNIOR_TOKEN = address(0);
	address public JUNIOR_OPERATOR = address(0);
	address public JUNIOR_MEMBERLIST = address(0);
	address public SENIOR_TRANCHE = address(0x675f5A545Fd57eC8Fe0916Fb61a2D9F19e2Da926);
	address public SENIOR_TOKEN = address(0x5b2F0521875B188C0afc925B1598e1FF246F9306);
	address public SENIOR_OPERATOR = address(0);
	address public SENIOR_MEMBERLIST = address(0x26129802A858F3C28553f793E1008b8338e6aEd2);
	address public RESERVE = address(0);
	address public ASSESSOR = address(0);
	address public POOL_ADMIN = address(0);
	address public COORDINATOR = address(0);
	address public CLERK = address(0);
	address public MGR = address(0);
	address public VAT = address(0);
	address public JUG = address(0);

    uint256 constant ONE = 10**27;
    address self;

	address public OLD_ADDRESS = address(0x074CB93f4bEde70F254D9e0C9A7378850E3Ef724);
	address public NEW_ADDRESS = address(0xe9EcEe30A7EcEB5d17A70A6423420878397d2ccC);
	uint256 public AMOUNT = 28742038686161978298101;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
		// check if NEW_ADDRESS is on the DROP memberlist
		require(MemberListLike(SENIOR_MEMBERLIST).hasMember(NEW_ADDRESS), "new-address-not-on-memberlist");
		
		// check that OLD_ADDRESS still has a pending redeem order of the same amount
		(,,uint redeemOrder) = TrancheLike(SENIOR_TRANCHE).users(OLD_ADDRESS);
		require(redeemOrder == AMOUNT, "old-address-has-unexpected-redeem-order");
		
		RootLike root = RootLike(address(ROOT));
		self = address(this);

		root.relyContract(SENIOR_TRANCHE, address(this));

		// transfer the users DROP to their new address
		TrancheLike(SENIOR_TRANCHE).authTransfer(SENIOR_TOKEN, NEW_ADDRESS, AMOUNT);

		// transfer the remaining DROP in the tranche to the spell
		uint trancheBalance = ERC20Like(SENIOR_TOKEN).balanceOf(SENIOR_TRANCHE);
		TrancheLike(SENIOR_TRANCHE).authTransfer(SENIOR_TOKEN, address(this), trancheBalance);

		// cancel the outstanding redeem order. With 0 DROP in the tranche, none will be reimbursed to them
		TrancheLike(SENIOR_TRANCHE).redeemOrder(OLD_ADDRESS, 0);

		// return the DROP to the tranche
		ERC20Like(SENIOR_TOKEN).transfer(SENIOR_TRANCHE, trancheBalance);

		root.denyContract(SENIOR_TRANCHE, address(this));
     }  
}