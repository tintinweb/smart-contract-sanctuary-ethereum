//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWatchScratchersWatchCaseRenderer.sol";

// TODO: this file is too big (about 26KB), refactor

contract DjOpExpRenderer is IWatchScratchersWatchCaseRenderer {
    constructor() {}
    
    function renderSvg(
        IWatchScratchersWatchCaseRenderer.CaseType caseType
    ) external pure returns (string memory) {
        string memory oysterCase = '<rect transform="rotate(185 429.17 571.2)" x="429.17" y="571.2" width="37" height="45" fill="#B2B2B2"/><rect transform="rotate(185 164.18 548.01)" x="164.18" y="548.01" width="37" height="45" fill="#B2B2B2"/><rect transform="rotate(185 210.66 636.4)" x="210.66" y="636.4" width="41" height="97" fill="#B2B2B2"/><rect transform="rotate(185 367.23 648.09)" x="367.23" y="648.09" width="44" height="96" fill="#B2B2B2"/><rect transform="rotate(185 304.3 644.59)" x="304.3" y="644.59" width="79" height="98" fill="#EBEBEB"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 467.34 134.86)" width="37" height="45" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 202.36 111.68)" width="37" height="45" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 263.65 30.714)" width="41" height="99" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 419.96 45.394)" width="44" height="99" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 357.2 39.903)" width="79" height="99" fill="#EBEBEB"/><rect transform="rotate(185 79.042 350.84)" x="79.042" y="350.84" width="42" height="75" fill="#B2B2B2"/><circle transform="rotate(185 296.92 338.79)" cx="296.92" cy="338.79" r="215" fill="#B2B2B2" stroke="#000" stroke-width="28"/><circle transform="rotate(185 297.38 339.33)" cx="297.38" cy="339.33" r="174.5" fill="#595958" stroke="#000" stroke-width="28"/><line x1="80.773" x2="24.986" y1="354.01" y2="349.12" stroke="#000" stroke-width="28"/><line x1="39.456" x2="47.212" y1="344.37" y2="255.71" stroke="#000" stroke-width="28"/><line x1="87.833" x2="48.777" y1="273.31" y2="269.9" stroke="#000" stroke-width="28"/><line x1="459.73" x2="419.52" y1="479.41" y2="583.3" stroke="#000" stroke-width="28"/><line transform="matrix(.1935 .9811 .9811 -.1935 125.9 446.29)" x2="111.4" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="430.71" x2="387.09" y1="575.05" y2="580.27" stroke="#000" stroke-width="28"/><line transform="matrix(.95721 .28939 .28939 -.95721 128.19 534.83)" x2="43.932" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="390.86" x2="369.1" y1="537.97" y2="660.54" stroke="#000" stroke-width="28"/><line transform="matrix(.0012116 1 1 -.0012116 183.82 518.61)" x2="124.49" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="384.17" x2="157.04" y1="649.57" y2="629.7" stroke="#000" stroke-width="28"/><line x1="313.21" x2="321.93" y1="657.42" y2="557.8" stroke="#000" stroke-width="28"/><line x1="220.57" x2="229.28" y1="649.31" y2="549.69" stroke="#000" stroke-width="28"/><line x1="372.02" x2="333.16" y1="593.3" y2="589.9" stroke="#000" stroke-width="28"/><line x1="217.62" x2="178.75" y1="579.79" y2="576.39" stroke="#000" stroke-width="28"/><line x1="312.24" x2="233.54" y1="611.16" y2="604.27" stroke="#000" stroke-width="28"/><line transform="matrix(-.1935 -.9811 -.9811 .1935 467.94 231.28)" x2="111.4" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="134.11" x2="174.32" y1="198.17" y2="94.275" stroke="#000" stroke-width="28"/><line transform="matrix(-.95721 -.28939 -.28939 .95721 465.65 142.75)" x2="43.932" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="163.14" x2="206.76" y1="102.52" y2="97.307" stroke="#000" stroke-width="28"/><line transform="matrix(-.0012116 -1 -1 .0012116 410.02 158.96)" x2="124.49" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="202.98" x2="224.74" y1="139.6" y2="17.035" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 435.59 61.819)" x2="228" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 382.24 29.044)" x2="100" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 289.6 20.939)" x2="100" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 413.86 115.13)" x2="39.013" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 259.45 101.62)" x2="39.013" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 358.08 87.16)" x2="79" y1="-14" y2="-14" stroke="#000" stroke-width="28"/>';
        string memory djDial = '<rect transform="rotate(152.3 367.51 470.72)" x="367.51" y="470.72" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="matrix(-.79119 -.61157 -.61157 .79119 388.16 219.94)" x="-1.4028" y=".17962" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="rotate(-27.703 230.03 207.02)" x="230.03" y="207.02" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="rotate(185 311.84 225.66)" x="311.84" y="225.66" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="matrix(.79119 .61157 .61157 -.79119 207.18 455.7)" x="1.4028" y="-.17962" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="rotate(123.61 422.06 418.83)" x="422.06" y="418.83" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="matrix(-.40054 -.91628 -.91628 .40054 433.21 279.07)" x="-1.3168" y="-.51574" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="rotate(-56.388 171.05 257.04)" x="171.05" y="257.04" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="rotate(95 446.79 346.84)" x="446.79" y="346.84" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="matrix(.40054 .91628 .91628 -.40054 157.91 394.81)" x="1.3168" y=".51574" width="10.034" height="35.72" fill="#EDEDED" stroke="#5C5F60" stroke-width="2"/><rect transform="rotate(185 215.52 362.78)" x="215.52" y="362.78" width="79" height="62" rx="31" fill="#F9F8F8" stroke="#5C5F60" stroke-width="2"/><path d="m303.45 479.7-19.264 10.352-17.174-13.54 8.595-18.601 22.608 1.978 5.235 19.811z" fill="#E3E3E3" stroke="#78797A" stroke-width="2"/><path d="m272.69 455.12c0.229-2.618 1.938-4.953 4.71-6.577 2.769-1.622 6.525-2.478 10.606-2.121 4.082 0.357 7.632 1.853 10.078 3.931 2.447 2.08 3.725 4.677 3.496 7.295s-1.939 4.954-4.71 6.577c-2.769 1.622-6.525 2.478-10.607 2.121-4.081-0.357-7.632-1.852-10.077-3.93-2.447-2.081-3.725-4.678-3.496-7.296z" fill="#E3E3E3" stroke="#78797A" stroke-width="2"/><path d="m280.84 453.82c0.224-2.555 3.116-4.746 6.911-4.414s6.263 2.992 6.04 5.547c-0.224 2.555-3.116 4.747-6.912 4.415-3.795-0.332-6.263-2.993-6.039-5.548z" fill="#fff" stroke="#66686A" stroke-width="2"/>';
        string memory opDial = '<rect transform="rotate(152.3 368.27 469.93)" x="368.27" y="469.93" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(-.79119 -.61157 -.61157 .79119 389.45 219.35)" x="-.70138" y=".089811" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="rotate(-27.703 229.44 205.81)" x="229.44" y="205.81" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(.79119 .61157 .61157 -.79119 207.07 455.29)" x=".70138" y="-.089811" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="rotate(123.61 422.84 417.7)" x="422.84" y="417.7" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(-.40054 -.91628 -.91628 .40054 434.45 278.83)" x="-.65841" y="-.25787" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="rotate(-56.388 170.44 256.19)" x="170.44" y="256.19" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="rotate(95 446.9 351.37)" x="446.9" y="351.37" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="rotate(95 448.03 338.42)" x="448.03" y="338.42" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 322.05 188.73)" x="-.54168" y=".45452" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 309.13 187.36)" x="-.54168" y=".45452" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="rotate(95 188.88 328.8)" x="188.88" y="328.8" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="rotate(95 190.01 315.85)" x="190.01" y="315.85" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(.40054 .91628 .91628 -.40054 157.84 394.06)" x=".65841" y=".25787" width="11.034" height="36.72" fill="#EDEDED" stroke="#5C5F60"/><path d="m304.12 478.96-19.901 10.693-17.741-13.986 8.909-19.279 23.307 2.039 5.426 20.533z" fill="#E3E3E3" stroke="#78797A"/><path d="m272.28 454.08c0.247-2.822 2.085-5.284 4.955-6.965 2.868-1.68 6.73-2.553 10.903-2.188s7.824 1.895 10.357 4.048c2.534 2.154 3.918 4.898 3.671 7.72s-2.086 5.284-4.955 6.965c-2.869 1.68-6.731 2.552-10.903 2.187-4.173-0.365-7.825-1.895-10.358-4.047-2.534-2.154-3.917-4.898-3.67-7.72z" fill="#E3E3E3" stroke="#78797A"/><path d="m280.42 452.78c0.256-2.929 3.492-5.216 7.453-4.869 3.96 0.346 6.75 3.161 6.494 6.089-0.257 2.928-3.492 5.215-7.453 4.869-3.961-0.347-6.75-3.161-6.494-6.089z" fill="#fff" stroke="#66686A"/>';
        string memory expDial = '<rect transform="matrix(-.88944 .45704 -.47276 -.88119 364.1 464.27)" x="-.6811" y="-.21207" width="10.491" height="34.724" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(-.79657 -.60455 -.6186 .78571 384.71 228.18)" x="-.70758" y=".090579" width="10.491" height="34.724" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(.88944 -.45704 .47276 .88119 230.46 215.32)" x=".6811" y=".21207" width="10.491" height="34.724" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(.79657 .60455 .6186 -.78571 210.06 450.07)" x=".70758" y="-.090579" width="10.491" height="34.724" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(-.56042 .82821 -.8373 -.54675 416.85 415.71)" x="-.69886" y=".14073" width="10.384" height="35.059" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(-.40809 -.91294 -.91952 .39305 428.01 284.23)" x="-.6638" y="-.25995" width="10.384" height="35.059" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(.56042 -.82821 .8373 .54675 174.33 263.18)" x=".69886" y="-.14073" width="10.384" height="35.059" fill="#EDEDED" stroke="#5C5F60"/><rect transform="matrix(.40809 .91294 .91952 -.39305 162.69 392.34)" x=".6638" y=".25995" width="10.384" height="35.059" fill="#EDEDED" stroke="#5C5F60"/><path d="m303.72 482.95-16.214-49.269-24.523 45.705 40.737 3.564z" fill="#F6F8F7" stroke="#5C5F60"/><path d="m288.77 231.17c2.168 0.83 8.101 2.388 18.392 3.288 4.765 0.417 14.402 0.012 14.835-4.943l1.668-19.058c0.222-2.541-1.43-7.806-9.815-8.54l-11.435-1c-3.017-0.264-9.152 0.351-9.552 4.925l-0.542 6.194c6e-3 1.761 1.447 5.408 7.164 5.908l22.87 2.001" stroke="#EDEDED" stroke-width="9"/><path d="m317.58 228.84c-7.053 2.595-20.887-0.296-27.412-2.205l-3.275 8.748c10.514 3.73 20.553 4.115 24.747 3.98 11.262-0.22 14.542-5.587 14.775-8.244l1.089-12.452 0.828-9.464c-0.1-8.04-7.733-11.05-11.537-11.55l-16.936-1.481c-8.836 0.03-11.568 6.014-11.829 9.003l-0.567 6.475c-0.299 8.004 7.264 10.674 11.083 11.008l19.426 1.699-0.392 4.483z" stroke="#5C5F60"/><path d="m438.7 336.05c-2.168-0.83-9.076-2.714-19.367-3.615-4.765-0.417-14.402-0.012-14.835 4.943l-1.668 19.058c-0.222 2.541 1.43 7.807 9.815 8.54l11.435 1.001c3.017 0.264 9.152-0.352 9.552-4.926l0.542-6.193c-6e-3 -1.761-1.447-5.408-7.164-5.908l-22.87-2.001" stroke="#EDEDED" stroke-width="9"/><path d="m408.91 338.04c7.053-2.595 21.866 0.575 28.391 2.484l3.275-8.748c-10.515-3.73-21.532-4.393-25.727-4.258-11.262 0.219-14.542 5.587-14.775 8.244l-1.089 12.452-0.828 9.464c0.1 8.039 7.733 11.049 11.537 11.549l16.936 1.482c8.836-0.03 11.568-6.015 11.829-9.003l0.567-6.475c0.299-8.005-7.264-10.674-11.083-11.008l-19.426-1.7 0.393-4.483z" stroke="#5C5F60"/><path d="m190.93 345.6c-4.793 0.239-15.941 0.482-22.178-0.459-7.798-1.176-11.099-2.946-10.009-9.763 1.09-6.818 10.082-8.006 15.962-7.491 4.704 0.411 9.473 0.828 11.27 0.986-9.68-0.354-28.876-2.922-28.224-10.37 0.814-9.31 7.674-8.71 18.454-7.767 5.362 0.799 16.46 2.625 17.959 3.547" stroke="#EDEDED" stroke-width="9"/><path d="m191.53 350.14-0.71-9.097-1.993-0.174c-6.844 0.204-13.565 0.152-16.07 0.1-6.809-0.194-9.059-1.629-9.333-2.322-0.657-1.664-0.07-3.018 0.305-3.487 1.405-2.286 7.762-2.667 10.765-2.572l11.457 1.003 0.828-9.464c-12.388-0.682-19.021-2.501-20.79-3.325-2.719-1.041-3.341-1.965-3.312-2.297l0.131-1.495c0.139-1.593 2.527-2.121 3.704-2.185 9.27-0.394 20.711 2.314 25.272 3.717l5.224-8.076c-8.522-3.556-23.329-4.885-29.668-5.105-9.2-0.403-13.106 6.382-13.909 9.825-1.355 6.306 2.752 10.614 4.975 11.979-3.796 2.078-4.574 8.3-4.489 11.152 0.463 8.472 10.873 11.491 16.02 11.941 12.786 0.717 19.723 0.22 21.593-0.118z" stroke="#5C5F60"/>';
        if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.DJ) {
            return string(abi.encodePacked(
                oysterCase,
                djDial
            ));
        } else if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.OP) {
            // do something with just the dial, DJ and OP only differ in the dial
            return string(abi.encodePacked(
                oysterCase,
                opDial
            ));
        } else if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.EXP) {
            // do something with just the dial, EXP and OP only differ in the dial
            // also shrink EXP's dial file size by using path instead of font
            return string(abi.encodePacked(
                oysterCase,
                expDial
            ));
        } else {
            revert IWatchScratchersWatchCaseRenderer.WrongCaseRendererCalled();
        }
    }
}

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWatchScratchersWatchCaseRenderer {
    enum CaseType { PP, AP, SUB, YACHT, DJ, OP, DD, DD_P, EXP, VC, GS, TANK, TANK_F, PILOT, AQ, SENATOR }

    error WrongCaseRendererCalled();

    function renderSvg(CaseType caseType)
        external
        pure
        returns (string memory);
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