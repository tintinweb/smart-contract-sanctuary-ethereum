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
import "./interfaces/IWatchScratchersWatchCaseRenderer.sol";

contract PpApRenderer is IWatchScratchersWatchCaseRenderer {
    constructor() {}
    function renderSvg(
        IWatchScratchersWatchCaseRenderer.CaseType caseType
    ) external pure returns (string memory) {
        if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.PP) {
            return '<mask id="c" fill="white"><path d="m224.65 13.678 304.99 26.683 45.017 204.9-0.505 5.779-427.37-37.39 0.656-7.497 77.21-192.48z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m224.65 13.678 304.99 26.683 45.017 204.9-0.505 5.779-427.37-37.39 0.656-7.497 77.21-192.48z" clip-rule="evenodd" fill="#D1D2D6" fill-rule="evenodd"/><path d="m224.65 13.678-25.987-10.424 7.733-19.28 20.694 1.8105-2.44 27.894zm304.99 26.683 2.441-27.894 20.493 1.7929 4.414 20.092-27.348 6.0084zm45.017 204.9 27.348-6.009 0.919 4.183-0.373 4.266-27.894-2.44zm-0.505 5.779 27.893 2.44-2.44 27.894-27.894-2.441 2.441-27.893zm-427.37-37.39-2.44 27.893-27.893-2.44 2.44-27.893 27.893 2.44zm0.656-7.497-27.893-2.44 0.361-4.134 1.545-3.85 25.987 10.424zm79.65-220.37 304.99 26.683-4.881 55.787-304.99-26.683 4.881-55.787zm329.9 48.568 45.017 204.9-54.695 12.017-45.018-204.9 54.696-12.017zm45.563 213.35-0.506 5.779-55.787-4.881 0.506-5.779 55.787 4.881zm-30.84 31.232-427.37-37.39 4.881-55.786 427.37 37.389-4.881 55.787zm-452.82-67.723 0.656-7.497 55.787 4.88-0.656 7.497-55.787-4.88zm2.562-15.481 77.21-192.48 51.974 20.849-77.21 192.48-51.974-20.848z" fill="#000" mask="url(#c)"/><rect transform="rotate(185 460.68 136.72)" x="460.68" y="136.72" width="187" height="51" rx="16" stroke="#000" stroke-width="28"/><line x1="534.59" x2="469.84" y1="118.09" y2="112.42" stroke="#000" stroke-width="28"/><line x1="271.6" x2="206.84" y1="95.08" y2="89.414" stroke="#000" stroke-width="28"/><mask id="a" fill="white"><path d="m156.83 811.8 304.99 26.683 79.914-193.97 0.506-5.779-427.37-37.39-0.656 7.497 42.613 202.96z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m156.83 811.8 304.99 26.683 79.914-193.97 0.506-5.779-427.37-37.39-0.656 7.497 42.613 202.96z" clip-rule="evenodd" fill="#D1D2D6" fill-rule="evenodd"/><path d="m156.83 811.8-27.402 5.753 4.268 20.33 20.694 1.81 2.44-27.893zm304.99 26.683-2.44 27.893 20.493 1.793 7.836-19.02-25.889-10.666zm79.914-193.97 25.889 10.666 1.631-3.96 0.374-4.266-27.894-2.44zm0.506-5.779 27.893 2.44 2.44-27.893-27.893-2.441-2.44 27.894zm-427.37-37.39 2.441-27.893-27.894-2.441-2.4404 27.894 27.893 2.44zm-0.656 7.497-27.893-2.44-0.3616 4.133 0.8525 4.061 27.402-5.754zm40.173 230.85 304.99 26.683 4.88-55.786-304.99-26.684-4.881 55.787zm333.32 9.456 79.914-193.97-51.778-21.332-79.914 193.97 51.778 21.332zm81.919-202.2 0.505-5.779-55.787-4.88-0.505 5.779 55.787 4.88zm-24.948-36.113-427.37-37.389-4.881 55.787 427.37 37.389 4.881-55.787zm-457.7-11.936-0.6559 7.497 55.787 4.881 0.656-7.498-55.787-4.88zm-0.165 15.691 42.613 202.96 54.805-11.507-42.613-202.96-54.805 11.507z" fill="#000" mask="url(#a)"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 396.65 717.62)" x="-15.167" y="12.726" width="187" height="51" rx="16" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 478.97 776.75)" x2="65" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 215.98 753.74)" x2="65" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><mask id="b" fill="white"><path d="m658.92 345.12-15.054 172.06-60.225 44.54-6.314-0.552 22.419-256.24 9.88 0.865-1.473 0.758 50.767 38.572z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m658.92 345.12-15.054 172.06-60.225 44.54-6.314-0.552 22.419-256.24 9.88 0.865-1.473 0.758 50.767 38.572z" clip-rule="evenodd" fill="#D1D2D6" fill-rule="evenodd"/><path d="m643.87 517.18 7.135 9.648 4.348-3.215 0.471-5.387-11.954-1.046zm15.054-172.06 11.954 1.046 0.577-6.596-5.272-4.005-7.259 9.555zm-75.279 216.6-1.046 11.954 4.527 0.396 3.654-2.702-7.135-9.648zm-6.314-0.552-11.954-1.046-1.046 11.954 11.955 1.046 1.045-11.954zm22.419-256.24 1.046-11.954-11.954-1.046-1.046 11.954 11.954 1.046zm9.88 0.865 5.491 10.67 36.936-19.004-41.381-3.621-1.046 11.955zm-1.473 0.758-5.491-10.671-16.926 8.71 15.157 11.516 7.26-9.555zm47.667 211.68 15.054-172.06-23.909-2.092-15.053 172.06 23.908 2.092zm-65.044 53.142 60.225-44.54-14.27-19.296-60.226 44.54 14.271 19.296zm-14.494 1.754 6.313 0.552 2.092-23.908-6.314-0.553-2.091 23.909zm11.51-269.24-22.419 256.24 23.909 2.091 22.418-256.24-23.908-2.092zm22.88-10.044-9.88-0.864-2.092 23.908 9.881 0.865 2.091-23.909zm2.971 23.383 1.474-0.758-10.981-21.341-1.474 0.758 10.981 21.341zm52.536 18.347-50.767-38.572-14.519 19.11 50.767 38.572 14.519-19.11z" fill="#000" mask="url(#b)"/><line x1="573.19" x2="645.94" y1="571.42" y2="508.58" stroke="#000" stroke-width="28"/><line x1="641.15" x2="656.32" y1="517.95" y2="344.48" stroke="#000" stroke-width="28"/><line x1="661.25" x2="585.52" y1="356.41" y2="292.65" stroke="#000" stroke-width="28"/><rect transform="rotate(185 75.897 507.59)" x="75.897" y="507.59" width="50" height="220" fill="#D1D2D6"/><rect transform="rotate(185 578.16 710.14)" x="578.16" y="710.14" width="521" height="526" rx="220" fill="#D1D2D6" stroke="#000" stroke-width="28"/><rect transform="rotate(185 516.13 627.42)" x="516.13" y="627.42" width="380" height="372" rx="165" fill="#88E3DE" stroke="#000" stroke-width="28"/><rect transform="rotate(185 216.09 425.34)" x="216.09" y="425.34" width="32.816" height="28.205" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="rotate(215.3 251.58 568.72)" x="251.58" y="568.72" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="matrix(-.90408 .42736 .42736 .90408 275.31 266.39)" x="-1.1918" y="3.3286" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="rotate(185 360.99 318.22)" x="360.99" y="318.22" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="rotate(185 324.59 585.06)" x="324.59" y="585.06" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="rotate(185 345.51 586.89)" x="345.51" y="586.89" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="matrix(.90408 -.42736 -.42736 -.90408 403.91 579.76)" x="1.1918" y="-3.3286" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="rotate(35.3 432.64 282.44)" x="432.64" y="282.44" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="matrix(.58849 -.8085 -.8085 -.58849 474.27 527.69)" x="-.55003" y="-3.4925" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="rotate(63.95 492.94 345.36)" x="492.94" y="345.36" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="matrix(-.58849 .8085 .8085 .58849 205.23 317.91)" x=".55003" y="3.4925" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="matrix(.087156 -.9962 -.9962 -.087156 499.62 446.52)" x="-2.2726" y="-2.7084" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><rect transform="rotate(243.95 191.56 505.23)" x="191.56" y="505.23" width="16" height="52" fill="#FEFEFD" stroke="#041418" stroke-width="5"/><line x1="94.898" x2="34.329" y1="550.68" y2="497.19" stroke="#000" stroke-width="28"/><line x1="39.032" x2="32.705" y1="506.74" y2="429.89" stroke="#000" stroke-width="28"/><line x1="41.146" x2="52.876" y1="354.72" y2="289.49" stroke="#000" stroke-width="28"/><line x1="45.892" x2="122.06" y1="298.76" y2="254.23" stroke="#000" stroke-width="28"/><line x1="33.689" x2="85.84" y1="443.64" y2="409.76" stroke="#000" stroke-width="28"/><line transform="matrix(.73124 .68212 .68212 -.73124 51.626 337.53)" x2="62.19" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="16.15" x2="27.742" y1="456.19" y2="323.7" stroke="#000" stroke-width="28"/>';
        } else if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.AP) {
            return '<rect transform="rotate(185 450.97 689.34)" x="450.97" y="689.34" width="245" height="38" fill="#D5D5D5"/><rect transform="rotate(185 509.46 78.115)" x="509.46" y="78.115" width="253" height="38" fill="#D5D5D5"/><rect transform="rotate(185 130.35 361.15)" x="130.35" y="361.15" width="47" height="65" fill="#D5D5D5"/><rect transform="rotate(29.906 490.78 513.06)" x="490.78" y="513.06" width="40.47" height="134.55" fill="#D5D5D5"/><rect transform="matrix(-.94026 .34047 .34047 .94026 193.48 481.03)" width="40.47" height="134.55" fill="#D5D5D5"/><rect transform="rotate(29.906 252.48 58.564)" x="252.48" y="58.564" width="40.47" height="134.55" fill="#D5D5D5"/><rect transform="matrix(-.94026 .34047 .34047 .94026 506.94 87.854)" width="40.47" height="134.55" fill="#D5D5D5"/><rect transform="rotate(185 466.33 628.45)" x="466.33" y="628.45" width="262" height="59" fill="#D5D5D5"/><rect transform="rotate(185 496.6 156.29)" x="496.6" y="156.29" width="262" height="62" fill="#D5D5D5"/><rect transform="rotate(185 411.06 640.68)" x="411.06" y="640.68" width="25" height="16" fill="#F9F9F9"/><rect transform="rotate(185 276.57 628.91)" x="276.57" y="628.91" width="25" height="16" fill="#F9F9F9"/><rect transform="rotate(185 462.54 98.102)" x="462.54" y="98.102" width="32" height="21" fill="#F9F9F9"/><rect transform="rotate(185 330.05 86.51)" x="330.05" y="86.51" width="33" height="21" fill="#F9F9F9"/><path d="m429.92 577.79-180.84-15.619-118.19-137.76 13.674-178.93 137.34-115.5 180.84 15.619 118.19 137.76-13.674 178.93-137.34 115.49z" fill="#D5D5D5" stroke="#000" stroke-width="28"/><circle transform="rotate(185 356.11 350.79)" cx="356.11" cy="350.79" r="166" fill="#2C4568" stroke="#000" stroke-width="28"/><path d="m426.3 540.67-6.671 9.469-11.514-1.263-4.85-10.75 6.67-9.469 11.514 1.263 4.851 10.75z" fill="#F8F8F8" stroke="#212121"/><line x1="423.54" x2="405.73" y1="535.52" y2="544" stroke="#000" stroke-width="5"/><path d="m540.51 438.36 1.314 11.508-9.44 6.712-10.772-4.804-1.313-11.508 9.44-6.712 10.771 4.804z" fill="#F8F8F8" stroke="#212121"/><line x1="535.02" x2="527.36" y1="436.35" y2="454.52" stroke="#000" stroke-width="5"/><path d="m553.81 300.29 1.233-11.517-9.486-6.647-10.738 4.878-1.233 11.518 9.486 6.646 10.738-4.878z" fill="#F8F8F8" stroke="#212121"/><line transform="matrix(-.41811 -.9084 -.9084 .41811 546.13 304.05)" x2="19.723" y1="-2.5" y2="-2.5" stroke="#000" stroke-width="5"/><path d="m169.28 269.46-1.809-11.441 9.142-7.113 10.968 4.334 1.809 11.441-9.142 7.114-10.968-4.335z" fill="#F8F8F8" stroke="#212121"/><line x1="174.85" x2="181.72" y1="271.24" y2="252.75" stroke="#000" stroke-width="5"/><path d="m156.07 406.29-1.411 11.497 9.383 6.792 10.811-4.713 1.411-11.497-9.383-6.792-10.811 4.713z" fill="#F8F8F8" stroke="#212121"/><line transform="matrix(.38064 .92472 .92472 -.38064 163.89 403.38)" x2="19.723" y1="-2.5" y2="-2.5" stroke="#000" stroke-width="5"/><path d="m458.58 175.02-6.718-9.435-11.508 1.321-4.796 10.775 6.718 9.435 11.508-1.321 4.796-10.775z" fill="#F8F8F8" stroke="#212121"/><line transform="matrix(-.90501 -.4254 -.4254 .90501 454.77 182.45)" x2="19.723" y1="-2.5" y2="-2.5" stroke="#000" stroke-width="5"/><path d="m252.27 525.97 4.925 10.484 11.558 0.755 6.644-9.745-4.925-10.483-11.558-0.756-6.644 9.745z" fill="#F8F8F8" stroke="#212121"/><line transform="matrix(.81446 .58021 .58021 -.81446 257.34 519.34)" x2="19.723" y1="-2.5" y2="-2.5" stroke="#000" stroke-width="5"/><path d="m284.12 161.83 6.671-9.469 11.514 1.263 4.851 10.75-6.671 9.469-11.514-1.263-4.851-10.75z" fill="#F8F8F8" stroke="#212121"/><line x1="286.89" x2="304.7" y1="166.98" y2="158.5" stroke="#000" stroke-width="5"/><rect transform="rotate(185 244.77 355.6)" x="244.77" y="355.6" width="37" height="30" rx="2.5" fill="#2C394B" stroke="#0F1923" stroke-width="3"/><rect transform="rotate(185 350.9 496.39)" x="350.9" y="496.39" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="rotate(185 366.75 257.86)" x="366.75" y="257.86" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="rotate(185 341.94 495.6)" x="341.94" y="495.6" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="rotate(220.61 271.14 468.74)" x="271.14" y="468.74" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="matrix(-.86065 .50919 .50919 .86065 291.23 220.41)" x="-.52719" y="2.0548" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="rotate(40.61 442.56 235.02)" x="442.56" y="235.02" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="matrix(.86062 -.50925 -.50925 -.86062 419.28 480.34)" x=".52705" y="-2.0548" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="matrix(.56198 -.82715 -.82715 -.56198 472.9 431.87)" x="-.39777" y="-2.0837" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="rotate(245.81 223.89 411.45)" x="223.89" y="411.45" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="matrix(-.56198 .82715 .82715 .56198 237.16 264.09)" x=".39777" y="2.0837" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="rotate(65.808 485.18 287.15)" x="485.18" y="287.15" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><rect transform="rotate(95 499.37 359.81)" x="499.37" y="359.81" width="6" height="52" rx="3" fill="#F8F8F8" stroke="#868582" stroke-width="3"/><line x1="128.62" x2="90.765" y1="357.99" y2="354.68" stroke="#000" stroke-width="28"/><line x1="127.14" x2="96.256" y1="294.62" y2="291.92" stroke="#000" stroke-width="28"/><line x1="88.549" x2="96.48" y1="368.54" y2="277.88" stroke="#000" stroke-width="28"/><line x1="548.04" x2="454.32" y1="477.54" y2="688.19" stroke="#000" stroke-width="28"/><line transform="matrix(.22678 .97394 .97394 -.22678 168.26 447.73)" x2="221" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="467.86" x2="192.92" y1="679.78" y2="655.72" stroke="#000" stroke-width="28"/><line x1="465.11" x2="420.28" y1="642.39" y2="638.46" stroke="#000" stroke-width="28"/><line x1="236.98" x2="192.16" y1="622.43" y2="618.51" stroke="#000" stroke-width="28"/><line x1="380.44" x2="276.83" y1="634.98" y2="625.92" stroke="#000" stroke-width="28"/><line x1="422.26" x2="426.71" y1="661.74" y2="610.93" stroke="#000" stroke-width="28"/><line x1="370.46" x2="374.91" y1="657.19" y2="606.39" stroke="#000" stroke-width="28"/><line x1="437.82" x2="357.13" y1="656.06" y2="649" stroke="#000" stroke-width="28"/><line x1="440.57" x2="360.87" y1="613.14" y2="606.16" stroke="#000" stroke-width="28"/><line x1="288.78" x2="293.22" y1="650.05" y2="599.24" stroke="#000" stroke-width="28"/><line x1="236.97" x2="241.42" y1="645.52" y2="594.71" stroke="#000" stroke-width="28"/><line x1="304.33" x2="223.64" y1="644.38" y2="637.32" stroke="#000" stroke-width="28"/><line x1="307.08" x2="227.38" y1="601.46" y2="594.48" stroke="#000" stroke-width="28"/><line transform="matrix(-.24166 -.97036 -.97036 .24166 553.11 267.64)" x2="230.55" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="174.64" x2="261.37" y1="222.17" y2="18.906" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 521.64 65.117)" x2="276" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 512.44 101.46)" x2="45" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 284.31 81.505)" x2="45" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 427.76 94.056)" x2="104" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 488.77 62.24)" x2="51" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 436.96 57.72)" x2="51" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 487.93 83.259)" x2="81" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 483.19 126.01)" x2="80" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 355.28 50.572)" x2="51" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 303.47 46.04)" x2="51" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 354.44 71.58)" x2="81" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 349.7 114.33)" x2="80" y1="-14" y2="-14" stroke="#000" stroke-width="28"/>';
        } else {
            revert IWatchScratchersWatchCaseRenderer.WrongCaseRendererCalled();
        }
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