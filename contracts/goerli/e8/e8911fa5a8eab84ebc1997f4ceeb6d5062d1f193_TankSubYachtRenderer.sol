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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWatchClubCaseRenderer.sol";


contract TankSubYachtRenderer is IWatchClubCaseRenderer {
    constructor() {}

    function renderSubYacht(
        IWatchClubCaseRenderer.CaseType caseType
    ) internal pure returns (string memory) {
        string memory diverCase = '<rect transform="rotate(185 335.98 672.76)" x="335.98" y="672.76" width="86" height="100" fill="#B2B2B3"/><rect transform="rotate(185 453.27 605.73)" x="453.27" y="605.73" width="60" height="67" fill="#B2B2B2"/><rect transform="rotate(185 453.27 605.73)" x="453.27" y="605.73" width="60" height="67" fill="#B2B2B2"/><rect transform="rotate(185 204.48 580.95)" x="204.48" y="580.95" width="60" height="67" fill="#B2B2B2"/><rect transform="rotate(185 204.48 580.95)" x="204.48" y="580.95" width="60" height="67" fill="#B2B2B2"/><rect transform="rotate(185 398.01 675.17)" x="398.01" y="675.17" width="51" height="110" fill="#B2B2B2"/><rect transform="rotate(185 230.73 659.54)" x="230.73" y="659.54" width="51" height="110" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 391.76 35.194)" width="86" height="100" fill="#B2B2B3"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 495.63 121.58)" width="60" height="67" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 495.63 121.58)" width="60" height="67" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 246.32 102.78)" width="60" height="67" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 246.32 102.78)" width="60" height="67" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 453.26 43.586)" width="51" height="110" fill="#B2B2B2"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 285.81 29.94)" width="51" height="110" fill="#B2B2B2"/><rect transform="rotate(185 96.804 411.92)" x="96.804" y="411.92" width="46" height="166" fill="#B2B2B2"/><rect transform="rotate(185 92.843 365.4)" x="92.843" y="365.4" width="43" height="68" fill="#B2B2B2"/><line x1="490.82" x2="445.67" y1="502.59" y2="617.09" stroke="#000" stroke-width="28"/><line x1="423.55" x2="396.52" y1="597.91" y2="688.9" stroke="#000" stroke-width="28"/><line x1="458.97" x2="409.86" y1="608.86" y2="607.92" stroke="#000" stroke-width="28"/><line transform="matrix(.19972 .97985 .97985 -.19972 142.08 468.08)" x2="123.08" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.11401 .99348 .99348 -.11401 191.97 574.83)" x2="94.921" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.98797 .15466 .15466 -.98797 143.44 567.24)" x2="49.114" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="410.7" x2="176.59" y1="679.3" y2="658.81" stroke="#000" stroke-width="28"/><line x1="340.95" x2="347.62" y1="662.38" y2="573.63" stroke="#000" stroke-width="38"/><line x1="246.27" x2="252.93" y1="654.1" y2="565.35" stroke="#000" stroke-width="38"/><line x1="325.22" x2="267.44" y1="623.63" y2="618.58" stroke="#000" stroke-width="28"/><line x1="418.88" x2="361.1" y1="608.74" y2="603.68" stroke="#000" stroke-width="28"/><line x1="234.67" x2="176.89" y1="591.62" y2="586.56" stroke="#000" stroke-width="28"/><line transform="matrix(-.19972 -.97985 -.97985 .19972 500.72 235.45)" x2="123.08" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.11401 -.99348 -.99348 .11401 450.84 128.7)" x2="94.921" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.98797 -.15466 -.15466 .98797 499.36 136.29)" x2="49.114" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="151.98" x2="197.13" y1="200.94" y2="86.444" stroke="#000" stroke-width="28"/><line x1="219.25" x2="246.28" y1="105.62" y2="14.634" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 464.99 58.666)" x2="235" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.09939 .99505 .99505 .09939 413.5 51.15)" x2="89.006" y1="-19" y2="-19" stroke="#000" stroke-width="38"/><line transform="matrix(-.09939 .99505 .99505 .09939 318.81 42.865)" x2="89.006" y1="-19" y2="-19" stroke="#000" stroke-width="38"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 371.15 98.639)" x2="58" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 460.8 129.57)" x2="58" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><path d="m281.12 100.8-62.263-5.4468-34.63-0.0182" stroke="#000" stroke-width="28"/><line transform="matrix(-.89096 .45407 .45407 .89096 142.9 229.24)" x2="84.906" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.076987 .99703 .99703 .076987 82.295 245.02)" x2="49.007" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><path d="m106.67 436.88-51.827-38.665 2.7018-30.882" stroke="#000" stroke-width="28"/><rect transform="rotate(185 87.862 364.96)" x="87.862" y="364.96" width="48" height="73" stroke="#000" stroke-width="28"/><circle transform="rotate(185 319.95 351.14)" cx="319.95" cy="351.14" r="229" fill="#0D4A29" stroke="#000" stroke-width="28"/><path d="m147.24 334.52c8.375-95.725 92.988-166.53 189-158.13 96.014 8.4 167.05 92.822 158.67 188.55s-92.988 166.53-189 158.13c-96.015-8.4-167.05-92.822-158.67-188.55z" fill="#00351D" stroke="#E0E0E0" stroke-width="5"/>';
        string memory diverDial = '<circle transform="rotate(185 374.21 465.3)" cx="374.21" cy="465.3" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 248.69 454.32)" cx="248.69" cy="454.32" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 267.6 238.14)" cx="267.6" cy="238.14" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 392.12 249.04)" cx="392.12" cy="249.04" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 424.04 423.48)" cx="424.04" cy="423.48" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 434.94 298.96)" cx="434.94" cy="298.96" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 206.87 404.48)" cx="206.87" cy="404.48" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><circle transform="rotate(185 217.76 279.96)" cx="217.76" cy="279.96" r="15.5" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><rect transform="rotate(185 460.26 370.94)" x="460.26" y="370.94" width="46" height="17" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><rect transform="rotate(95 341.75 211)" x="341.75" y="211" width="46" height="17" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><path d="m329.17 490.47-15.642-48.68-23.858 45.224 39.5 3.456z" fill="#FCFEFF" stroke="#9EA09F" stroke-width="3"/><rect transform="rotate(185 245.89 377.28)" x="245.89" y="377.28" width="87" height="65" rx="32.5" fill="#FCFDFD" stroke="#9EA09F"/>';
        string memory yachtBezel = '<path d="M305.258 530.539L277.82 555.995L327.858 560.373L305.258 530.539Z" fill="#E2E2E0"/><rect x="268.256" y="540.352" width="6.70349" height="15.1348" transform="rotate(-163.545 268.256 540.352)" fill="#FAFAFA"/><rect x="248.781" y="533.629" width="6.70349" height="15.1348" transform="rotate(-155.737 248.781 533.629)" fill="#FAFAFA"/><rect x="230.508" y="525.004" width="6.70349" height="15.1348" transform="rotate(-147.673 230.508 525.004)" fill="#FAFAFA"/><rect x="196.264" y="501.931" width="6.70349" height="15.1348" transform="rotate(-138.172 196.264 501.931)" fill="#FAFAFA"/><rect x="180.919" y="487.539" width="6.70349" height="15.1348" transform="rotate(-130.471 180.919 487.539)" fill="#FAFAFA"/><rect x="168.463" y="472.396" width="6.70349" height="15.1348" transform="rotate(-126.46 168.463 472.396)" fill="#FAFAFA"/><rect x="131.295" y="399.88" width="6.70349" height="15.1348" transform="rotate(-98.9408 131.295 399.88)" fill="#FAFAFA"/><rect x="127.729" y="379.492" width="6.70349" height="15.1348" transform="rotate(-92.1164 127.729 379.492)" fill="#FAFAFA"/><rect x="126.304" y="360.295" width="6.70349" height="15.1348" transform="rotate(-88.2349 126.304 360.295)" fill="#FAFAFA"/><rect x="208.694" y="524.099" width="13" height="26" transform="rotate(-143.054 208.694 524.099)" fill="#FAFAFA"/><rect width="13" height="26" transform="matrix(0.891433 -0.453154 -0.453154 -0.891433 403.676 541.157)" fill="#FAFAFA"/><rect x="435.86" y="177.936" width="13" height="26" transform="rotate(36.9462 435.86 177.936)" fill="#FAFAFA"/><rect width="13" height="26" transform="matrix(-0.891433 0.453154 0.453154 0.891433 241.497 160.634)" fill="#FAFAFA"/><rect x="142.976" y="331.639" width="13" height="26" transform="rotate(95 142.976 331.639)" fill="#FAFAFA"/><rect x="527.507" y="365.281" width="13" height="26" transform="rotate(95 527.507 365.281)" fill="#FAFAFA"/>';
        string memory subBezel = '<path d="m305.84 529.59-28.993 28.331 52.627 4.604-23.634-32.935z" fill="#9E9E9E"/><rect transform="rotate(185.58 287.87 543.17)" x="287.87" y="543.17" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(196.46 267.35 539.27)" x="267.35" y="539.27" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(204.26 247.87 532.54)" x="247.87" y="532.54" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(212.33 229.6 523.92)" x="229.6" y="523.92" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(221.83 195.36 500.85)" x="195.36" y="500.85" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(229.53 180.01 486.46)" x="180.01" y="486.46" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(233.54 167.55 471.31)" x="167.55" y="471.31" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(237.52 156.24 455.26)" x="156.24" y="455.26" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(247.22 137.99 418.54)" x="137.99" y="418.54" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(261.06 130.39 398.8)" x="130.39" y="398.8" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(267.88 126.82 378.41)" x="126.82" y="378.41" width="6.7035" height="15.135" fill="#F5F5F5"/><rect transform="rotate(-88.235 125.4 359.21)" x="125.4" y="359.21" width="6.7035" height="15.135" fill="#F5F5F5"/><ellipse transform="rotate(185 304.19 548.51)" cx="304.19" cy="548.51" rx="11.5" ry="11" fill="#D7D7D7"/><rect transform="rotate(216.95 205.42 525.82)" x="205.42" y="525.82" width="13" height="30" fill="#F5F5F5"/><rect transform="matrix(.89143 -.45315 -.45315 -.89143 403.5 543.15)" width="13" height="30" fill="#F5F5F5"/><rect transform="rotate(36.946 435.87 173.23)" x="435.87" y="173.23" width="13" height="30" fill="#F5F5F5"/><rect transform="matrix(-.89143 .45315 .45315 .89143 238.61 156.32)" width="13" height="30" fill="#F5F5F5"/><rect transform="rotate(95 142.07 330.56)" x="142.07" y="330.56" width="13" height="30" fill="#F5F5F5"/><rect transform="rotate(95 531.67 363.64)" x="531.67" y="363.64" width="13" height="30" fill="#F5F5F5"/>';
        if (caseType == IWatchClubCaseRenderer.CaseType.YACHT) {
            return string(abi.encodePacked(
                diverCase,
                yachtBezel,
                diverDial
            ));
        } else {
            // SUB = YM but swap polished links + crown and bezel
            return string(abi.encodePacked(
                diverCase,
                subBezel,
                diverDial
            ));
        }
    }

    function renderSvg(
        IWatchClubCaseRenderer.CaseType caseType
    ) external pure returns (string memory) {
        if (caseType == IWatchClubCaseRenderer.CaseType.TANK) {
            return '<rect transform="rotate(185 445.26 890.74)" x="445.26" y="890.74" width="292" height="186" fill="#0C0C0C"/><rect transform="rotate(185 506.55 224.55)" x="506.55" y="224.55" width="292" height="186" fill="#0C0C0C"/><rect transform="rotate(185 514.08 735.15)" x="514.08" y="735.15" width="43" height="516" fill="#F7E5B0"/><rect transform="rotate(185 161.17 707.28)" x="161.17" y="707.28" width="43" height="519" fill="#F7E5B0"/><rect transform="rotate(185 477.84 701.86)" x="477.84" y="701.86" width="337" height="36" fill="#F7E5B0"/><rect transform="rotate(185 524.98 266.31)" x="524.98" y="266.31" width="337" height="36" fill="#F7E5B0"/><circle transform="rotate(185 83.821 432.49)" cx="83.821" cy="432.49" r="32" fill="#1C55B4" stroke="#000" stroke-width="28"/><rect transform="rotate(185 129.45 484.67)" x="129.45" y="484.67" width="50" height="94" fill="#F7E5B0"/><line x1="131.95" x2="107.38" y1="466.61" y2="483.54" stroke="#000" stroke-width="28"/><line transform="matrix(-.71252 -.70165 -.70165 .71252 127.32 417.23)" x2="29.833" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="109.11" x2="78.074" y1="499.67" y2="452.79" stroke="#000" stroke-width="28"/><line transform="matrix(-.68836 .72537 .72537 .68836 130.54 380.37)" x2="56.223" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="87.656" x2="93.409" y1="468.97" y2="403.22" stroke="#000" stroke-width="14"/><rect transform="rotate(185 474.1 664.39)" x="474.1" y="664.39" width="308" height="394" fill="#F8F8F8" stroke="#000" stroke-width="28"/><path d="m331.63 581.66 16.728 44.628-12.146-1.063-16.727-44.627 12.145 1.062z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="352.01" x2="333.08" y1="625.6" y2="623.95" stroke="#010101" stroke-width="2"/><line x1="355.58" x2="346.62" y1="584.76" y2="583.98" stroke="#010101" stroke-width="2"/><line x1="352.41" x2="316.14" y1="584.1" y2="622.24" stroke="#010101" stroke-width="2"/><line x1="321.13" x2="281.28" y1="622.9" y2="619.42" stroke="#010101" stroke-width="2"/><line x1="335.66" x2="284.85" y1="583.02" y2="578.57" stroke="#010101" stroke-width="2"/><line x1="306.77" x2="310.17" y1="620.64" y2="581.79" stroke="#010101" stroke-width="11"/><line x1="289.84" x2="293.24" y1="619.16" y2="580.31" stroke="#010101" stroke-width="11"/><path d="m259.86 574.38-29.051 39.618-12.818-1.121 29.051-39.619 12.818 1.122zm-8.456-6.763-0.146-0.108-0.066 0.089 0.212 0.019z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="233.55" x2="214.62" y1="614.24" y2="612.58" stroke="#010101" stroke-width="2"/><line x1="262.03" x2="243.1" y1="575.57" y2="573.92" stroke="#010101" stroke-width="2"/><path d="m194.94 527.74 0.211 0.485 42.523-18.51 1.091-12.472-42.786 18.625-1.039 11.872z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m193.34 546.01 0.212 0.486 42.522-18.51 1.091-12.472-42.786 18.624-1.039 11.872z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="193.95" x2="197.35" y1="550.54" y2="511.69" stroke="#010101" stroke-width="2"/><line x1="235.72" x2="239.12" y1="532.11" y2="493.26" stroke="#010101" stroke-width="2"/><line x1="242.42" x2="201.58" y1="466.95" y2="463.38" stroke="#010101" stroke-width="11"/><line x1="243.82" x2="202.97" y1="451.01" y2="447.44" stroke="#010101" stroke-width="11"/><line x1="245.3" x2="204.45" y1="434.08" y2="430.5" stroke="#010101" stroke-width="11"/><line x1="241.59" x2="246.04" y1="476.41" y2="425.61" stroke="#010101" stroke-width="2"/><line x1="201.75" x2="206.19" y1="472.93" y2="422.12" stroke="#010101" stroke-width="2"/><path d="m210.29 375.3 37.802 26.876-1.112 12.706-37.801-26.875 1.111-12.707z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m211.88 357.14 37.802 26.875-1.112 12.707-37.802-26.875 1.112-12.707z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m213.44 339.2 37.801 26.875-1.111 12.706-37.802-26.875 1.112-12.706z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m215.92 322.36 37.801 26.875-1.111 12.707-37.802-26.876 1.112-12.706z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="246.65" x2="254.1" y1="418.62" y2="344.99" stroke="#010101" stroke-width="2"/><line x1="208.89" x2="216.34" y1="391.22" y2="317.59" stroke="#010101" stroke-width="2"/><path d="m256.14 287.26 24.516 29.542-1.381 15.559-38.548-46.449 15.413 1.348z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="280.26" x2="282.05" y1="332.58" y2="289.57" stroke="#010101" stroke-width="2"/><line x1="285.02" x2="277.06" y1="289.78" y2="289.09" stroke="#010101" stroke-width="2"/><line x1="261.12" x2="238.2" y1="287.69" y2="285.69" stroke="#010101" stroke-width="2"/><path d="m400.78 332.07 2.731-31.212-10.958-0.958-3.835 43.833 12.062-11.663z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="407.41" x2="389.48" y1="302.2" y2="300.63" stroke="#010101" stroke-width="2"/><line x1="392.77" x2="405.54" y1="338.4" y2="326.46" stroke="#010101" stroke-width="2"/><path d="m447.29 305.69-28.068 38.701-10.991-0.961-1.245-0.904 27.526-37.954 12.778 1.118z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m466.18 307.34-28.068 38.7-10.991-0.961-1.245-0.903 27.527-37.954 12.777 1.118z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="469.17" x2="428.33" y1="307.6" y2="304.03" stroke="#010101" stroke-width="2"/><line x1="469.17" x2="428.33" y1="307.6" y2="304.03" stroke="#010101" stroke-width="2"/><line x1="440.69" x2="402.84" y1="346.27" y2="342.96" stroke="#010101" stroke-width="2"/><line x1="440.69" x2="402.84" y1="346.27" y2="342.96" stroke="#010101" stroke-width="2"/><path d="m405.67 323.91 2.816-2.964-1.712-1.627 17.47-17.9 3.578 3.493-20.304 20.803-1.848-1.805z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m485.2 342.46-25.272 20.737-18.776 1.177 45.389-37.244-1.341 15.33z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="483.88" x2="486.06" y1="346.03" y2="321.13" stroke="#010101" stroke-width="2"/><path d="m482.2 376.69-42.896 19.89 1.105-12.638 42.897-19.89-1.106 12.638z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m480.65 394.38-42.896 19.89 1.105-12.637 42.897-19.89-1.106 12.637z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m479.08 412.32-42.897 19.89 1.106-12.638 42.896-19.89-1.105 12.638z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="435.93" x2="440.81" y1="435.19" y2="379.41" stroke="#010101" stroke-width="2"/><line x1="477.69" x2="483.09" y1="416.76" y2="355" stroke="#010101" stroke-width="2"/><line x1="447.13" x2="482.43" y1="362.9" y2="360.97" stroke="#010101" stroke-width="2"/><line x1="473.25" x2="433.4" y1="456.02" y2="452.54" stroke="#010101" stroke-width="11"/><path d="m429.72 494.66 42.668-17.265 1.076-12.302-42.667 17.265-1.077 12.302z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="471.03" x2="473.99" y1="481.43" y2="447.56" stroke="#010101" stroke-width="2"/><line x1="432.14" x2="434.14" y1="466.98" y2="444.07" stroke="#010101" stroke-width="2"/><line x1="469.29" x2="469.98" y1="501.35" y2="493.38" stroke="#010101" stroke-width="2"/><line x1="429.44" x2="431.1" y1="497.87" y2="478.94" stroke="#010101" stroke-width="2"/><line x1="469.94" x2="432.88" y1="498.18" y2="462.81" stroke="#010101" stroke-width="2"/><path d="m423.84 550.35 41.067 1.021 0.961-10.979-41.067-1.021-0.961 10.979z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="463.67" x2="465.15" y1="554.06" y2="537.13" stroke="#010101" stroke-width="2"/><line x1="423.56" x2="425.04" y1="553.57" y2="536.63" stroke="#010101" stroke-width="2"/><line x1="461.32" x2="462.28" y1="580.96" y2="570" stroke="#010101" stroke-width="2"/><line x1="426.52" x2="427.4" y1="519.7" y2="509.73" stroke="#010101" stroke-width="2"/><line x1="461.88" x2="427.17" y1="576.55" y2="514.29" stroke="#010101" stroke-width="2"/><path d="m403.31 589.94 37.271 44.417-15.497-1.355-37.271-44.418 15.497 1.356z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><path d="m381.42 587.02 20.895 43.989-12.706-1.112-20.894-43.988 12.705 1.111z" clip-rule="evenodd" fill="#010101" fill-rule="evenodd"/><line x1="445.57" x2="420.66" y1="634.79" y2="632.61" stroke="#010101" stroke-width="2"/><line x1="409.7" x2="384.8" y1="631.66" y2="629.48" stroke="#010101" stroke-width="2"/><line x1="407.39" x2="365.55" y1="589.29" y2="585.63" stroke="#010101" stroke-width="2"/><line x1="426.31" x2="418.34" y1="590.95" y2="590.25" stroke="#010101" stroke-width="2"/><line x1="405.79" x2="422.4" y1="631.02" y2="590.31" stroke="#010101" stroke-width="2"/><rect transform="rotate(185 411.14 575.06)" x="411.14" y="575.06" width="165" height="218" stroke="#070707"/><rect transform="rotate(185 400.06 564.06)" x="400.06" y="564.06" width="141" height="197" stroke="#070707"/><line x1="353.19" x2="356.9" y1="338.62" y2="296.14" stroke="#000" stroke-width="11"/><line x1="363.01" x2="343.56" y1="339.22" y2="337.52" stroke="#000" stroke-width="2"/><line x1="365.59" x2="345.06" y1="297.27" y2="295.48" stroke="#000" stroke-width="2"/><line x1="336.44" x2="315.91" y1="294.28" y2="292.49" stroke="#000" stroke-width="2"/><path d="m339 322-6.432-28.626-11.376-0.995 10.234 45.551 7.574-15.93z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="337.34" x2="350.79" y1="323.14" y2="296.17" stroke="#000" stroke-width="2"/><path d="m533.59 695.7c-3.017 34.489-29.88 61.163-62.922 65.199l2.533-28.947c17.385-4.636 30.837-19.732 32.495-38.692l38.175-436.33c1.659-18.96-8.967-36.162-25.284-43.747l2.533-28.947c31.839 9.713 53.662 40.646 50.644 75.135l-38.174 436.33zm-329.28-538.96c-32.576 4.453-58.92 30.933-61.907 65.068l-38.174 436.33c-2.986 34.135 18.36 64.787 49.667 74.829l2.546-29.104c-15.769-7.805-25.945-24.7-24.32-43.285l38.175-436.33c1.626-18.585 14.582-33.456 31.467-38.404l2.546-29.104z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="464.68" x2="471.83" y1="771.98" y2="690.29" stroke="#000" stroke-width="28"/><line x1="157.85" x2="165.09" y1="745.14" y2="662.45" stroke="#000" stroke-width="28"/><line x1="473.55" x2="170.8" y1="704.5" y2="676.99" stroke="#000" stroke-width="28"/><line x1="465.02" x2="437.67" y1="769.32" y2="897.12" stroke="#000" stroke-width="28"/><line transform="matrix(.036281 .99934 .99934 -.036281 172.29 741.97)" x2="130.7" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="452.67" x2="150.82" y1="886.37" y2="859.96" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 531.77 165.8)" x2="82" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 224.94 138.96)" x2="83" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.99648 -.083835 -.083835 .99648 513.66 246.53)" x2="304" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.036281 -.99934 -.99934 .036281 503.7 167.77)" x2="130.7" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="210.97" x2="238.32" y1="140.43" y2="12.623" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 524.63 63.793)" x2="303" y1="-14" y2="-14" stroke="#000" stroke-width="28"/>';
        } else if (
            caseType == IWatchClubCaseRenderer.CaseType.YACHT || 
            caseType == IWatchClubCaseRenderer.CaseType.SUB
        ) {
            return renderSubYacht(caseType);
        } else {
            revert IWatchClubCaseRenderer.WrongCaseRendererCalled();
        }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWatchClubCaseRenderer {
    enum CaseType { PP, AP, SUB, YACHT, DJ, OP, DD, DD_P, EXP, VC, GS, TANK, TANK_F, PILOT, AQ, SENATOR }

    error WrongCaseRendererCalled();

    function renderSvg(CaseType caseType)
        external
        pure
        returns (string memory);
}