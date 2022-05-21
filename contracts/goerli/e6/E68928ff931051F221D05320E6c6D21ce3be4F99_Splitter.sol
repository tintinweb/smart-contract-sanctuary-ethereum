//SPDX-License-Identifier: GPL-3.0

/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXXXKKKKKKKKKKKKXXXNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kdolc:;,,'''.............'''',;;:clodk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMWN0xo:,...                                    ...,:lx0XWMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMWKxc,..                                                ..'cd0NMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMWKx:..                                                        ..;o0NMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMW0l'.                                                              ..:kXMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMW0c..                                                                   .;xNMMMMMMMMMMM*/
/*MMMMMMMMMMMMXo.                                       ,:.                              .:OWMMMMMMMMM*/
/*MMMMMMMMMMWO;.                                      .,ONx'                               .oXMMMMMMMM*/
/*MMMMMMMMMNd.                                     ..'lKWMWOc.                              .cKMMMMMMM*/
/*MMMMMMMMNo.                                    .:dOKWMMMMMW0o;.                            .;0MMMMMM*/
/*MMMMMMMNo.                                     .ck0XMMMMMMWKx:.                             .;0MMMMM*/
/*MMMMMMWd.                                      . ..,dXMMMKo'.                                .cXMMMM*/
/*MMMMMWk'                                     .,l;.  .:KWO,.                                   .dNMMM*/
/*MMMMMX:.                                   .'oKWXdc,..;o'                                      ,OMMM*/
/*MMMMWx.                                    ..c0WKl;'. ..                                       .lNMM*/
/*MMMMX:.                                       'c,.                                              ,0MM*/
/*MMMMO'                                                                                          .xWM*/
/*MMMWd.                                                                                          .lNM*/
/*MMMNc.                       .:dddddddddddddddo:.            .cdddddl'.                          :XM*/
/*MMMK;                        .lXMMMMMMMMMMMMMMXc.            .:0MMMXl.                           ;KM*/
/*MMM0,                         .xWMMMMMMMMMMMMWx.              .;KMNl.                            ,0M*/
/*MMM0,                         .lNMMMMMMMMMMMMNl.               .oNk.                             'OM*/
/*MMMO'                         .cNMMMMMMMMMMMMXc.                cKo.                             'OM*/
/*MMMO'                         .cNMMMMMMMMMMMMXc.                :Ko.                             'kM*/
/*MMMO,                         .cNMMMMMMMMMMMMXc                 :Ko.                             .kM*/
/*MMM0,                         .cNMMMMMMMMMMMMXc.                :Ko.                             'kM*/
/*MMMK:                         .cNMMMMMMMMMMMMXc.                :Ko.                             'OM*/
/*MMMNl.                        .cNMMMMMMMMMMMMXc.                :Ko.                             ,0M*/
/*MMMWd.                        .cNMMMMMMMMMMMMXc.                :Ko.                             :XM*/
/*MMMM0,                        .cNMMMMMMMMMMMMXc.                :Ko.                            .lNM*/
/*MMMMNl.                       .cNMMMMMMMMMMMMXc                 :Ko.                            .xMM*/
/*MMMMMO,                       .cXMMMMMMMMMMMMNc.               .cKl.                            ;KMM*/
/*MMMMMNo.                       ;0MMMMMMMMMMMMWo.               .d0;                            .dWMM*/
/*MMMMMMXc.                      .dNMMMMMMMMMMMMO,               ;0x.                           .:KMMM*/
/*MMMMMMM0;.                      .xNMMMMMMMMMMMWx'            .;Ok,                            ,OWMMM*/
/*MMMMMMMM0:.                      .c0NMMMMMMMMMMW0l;,..   ...;dOd'                            'xWMMMM*/
/*MMMMMMMMMKc.                       .:dOKNWWMMMMMMWNX0kdddddxxl,.                            'xWMMMMM*/
/*MMMMMMMMMMNd'.                        ..,;:ccccccccccccc:;,..                             .;OWMMMMMM*/
/*MMMMMMMMMMMW0c.                                                                          .lKMMMMMMMM*/
/*MMMMMMMMMMMMMNk:.                                                                      .:ONMMMMMMMMM*/
/*MMMMMMMMMMMMMMMNOc'.                                                                 .:kNMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMWKx:'.                                                          ..;o0WMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMWKko;'..                                                 ..':d0NMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMWXOxoc;'...                                   ...',:ox0XWMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKOkxdollcc:::;;;;;;;;;;;;;;;;;::ccloodkO0XNWMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWNNNWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/


pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

contract Splitter {

    address public co_n1 = 0x0000000000000000000000000000000000000001;
    address public co_n2 = 0x0000000000000000000000000000000000000002;
    address public co_n3 = 0x0000000000000000000000000000000000000003;
    address public co_n4 = 0x0000000000000000000000000000000000000004;
    address public co_n5 = 0x0000000000000000000000000000000000000005;

    constructor() {}

    receive() external payable {

        require(msg.value >= 0.00005 ether, "Error: not enought to split");
        uint256 share = msg.value / 5;

        (bool success, ) = co_n1.call{value: share}("");
        require(success, "Error splitting(1)");
        (success, ) = co_n2.call{value: share}("");
        require(success, "Error splitting(2)");
        (success, ) = co_n3.call{value: share}("");
        require(success, "Error splitting(3)");
        (success, ) = co_n4.call{value: share}("");
        require(success, "Error splitting(4)");
        (success, ) = co_n5.call{value: share}("");
        require(success, "Error splitting(5)");
    }

    function withrawERC20(address _token, uint256 _amount) external onlyCo {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance >= _amount, "Not enough balance");
        uint256 share = _amount / 5;
        bool success = IERC20(_token).transfer(co_n1, share);
        require(success, "Error transfering ERC20(1)");
        success = IERC20(_token).transfer(co_n2, share);
        require(success, "Error transfering ERC20(2)");
        success = IERC20(_token).transfer(co_n3, share);
        require(success, "Error transfering ERC20(3)");
        success = IERC20(_token).transfer(co_n4, share);
        require(success, "Error transfering ERC20(4)");
        success = IERC20(_token).transfer(co_n5, share);
        require(success, "Error transfering ERC20(5)");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getERC20Balance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }


    modifier onlyCo {
        require(msg.sender == co_n1 || msg.sender == co_n2 || msg.sender == co_n3 
        || msg.sender == co_n4 || msg.sender == co_n5, "You are not a co-founder");
        _;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

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

}