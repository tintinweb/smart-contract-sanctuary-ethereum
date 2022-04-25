/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: MIT
// File: contracts/BiTSNFTUtils.sol


// @author [email protected]
pragma solidity ^0.8.12;

enum DepositUnits {
    MILLI, //0.001
    CENTI, //0.01
    DECI, //0.1
    ONE, //1
    DECA //10
}


//Contract Meta data
struct ContractMeta {
    string mintName;
    string mintDescription;
    string depositSymbol;
    string mintSymbol;
}
//Token Meta data
struct TokenMeta {
    string userText;
    uint tokenId;
    uint depositAmount;
}
//SVGMeta picks the right image to build
struct SVGMeta {
    string backgroundHue;
    string strokeHue;
    string depositUnitInString;
    string depositUnitName;
    bytes svgLogo;
 
}
//SVG Psuedo Random Seed
struct Seed {
        uint48 scale;
        uint48 rotate;
        uint48 strokeWidth;
        uint48 strokePatternHue;
        uint48 strokeSaturation;
        uint48 strokeLightness;
    }


bytes constant SVG_PREFIX = '<svg viewBox="0 0 250 250" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><defs><filter id="convolve"><feConvolveMatrix kernelMatrix="1 0 0 0 1 0 0 0 -1"/></filter>';

bytes constant META_TEXT_PREFIX = '<text dy="8"><textPath startOffset="518" xlink:href="#reversePath">';
bytes constant USER_TEXT_PREFIX = '<text><textPath startOffset="518" xlink:href="#frontPath">';
bytes constant UNIT_TEXT_PREFIX = '<text style="fill: #eeb32b; font-family: Arial, sans-serif; font-size: 44px; font-weight: 700; text-anchor: middle; filter: url(#convolve);" x="125" y="125">';

//bytes constant DeciSVGLogo = '<g transform="matrix(0.08, 0, 0, 0.08, 75, 90)" style="fill: #eeb32b; filter: url(#convolve);"><path d="m395.63-132.82c3.4468-7.1465 7.9529-13.708 12.649-20.08 31.448 17.677 57.931 44.128 75.228 75.813-8.7118 4.3796-17.534 8.4746-26.246 12.838-9.3127-8.3482-18.499-16.87-27.4-25.661-3.763-4.0476-10.198-2.4507-12.664 2.1503-9.3127 14.957-13.329 32.507-16.791 49.583-6.4667 3.2096-13.17 5.8975-19.779 8.7751-1.6285-34.847-0.4427-71.418 15.005-103.42z" ></path><path d="m844.82-79.16c20.981-18.072 42.721-35.401 66.279-50.042 13.091 36.065 20.285 74.801 16.744 113.21-4.1108 51.322-27.97 99.735-62.516 137.43-10.072 10.973-20.823 21.345-32.365 30.768-3.763 3.099-7.7947 5.8975-11.004 9.5814-0.2845-0.0316-0.8696-0.1106-1.1542-0.1423 16.412-23.716 30.404-49.156 42.041-75.56 19.321-44.286 30.436-93.379 23.637-141.74-61.378 27.874-117.44 66.927-166.54 112.98 36.697-49.678 78.406-95.751 124.87-136.48z" ></path><path d="m500.55-70.907c29.472-12.38 62.311-19.574 94.201-13.882 24.206 4.2373 46.389 18.198 60.777 38.104 17.424 23.495 25.63 52.35 30.325 80.857 1.1384 5.6603 1.5969 11.431 1.502 17.202-6.1505-30.831-15.463-62.058-34.42-87.624-14.182-19.274-35.669-33.361-59.56-36.713-32.191-4.6168-64.477 5.2176-93.427 18.657-46.152 25.329-93.458 49.298-144.02 64.54-59.971 18.546-125.3 24.76-186.38 7.7473 11.479 10.214 24.475 18.578 37.836 26.135 25.345 13.977 52.761 25.503 81.663 29.14-17.566-0.1107-34.705-4.8065-51.591-9.202-50.089-14.072-98.328-42.152-127.29-86.438 38.42 23.985 83.94 34.958 128.99 35.148 43.432 0.0949 86.501-8.9806 127.28-23.558 25.835-9.7553 51.275-20.57 76.224-32.428 19.416-8.9489 38.341-18.973 57.9-27.685z" ></path><path d="m2.6056 58.332c-0.4585-9.1861-1.4704-18.42-0.0791-27.574 9.5814 29.772 24.238 59.164 48.286 79.892 17.961 15.716 41.203 24.807 64.904 26.784 25.376 2.1661 50.927-2.4349 75.054-10.198 54.469-20.459 111.78-34.373 170.03-37.013 29.598-1.755 59.291 0.4269 88.573 4.7749-7.8738 0.4743-15.732-0.0949-23.606-0.3636-67.054-2.4823-134.72 7.9371-197.46 31.97-16.096 5.8659-31.385 13.929-48.002 18.341-31.021 8.6486-64.445 11.194-95.893 3.257-19.084-4.8381-37.171-14.467-50.69-28.918 8.6644 16.538 18.752 32.586 32.144 45.741 20.428 20.728 47.022 34.452 74.786 42.468-39.084-4.759-76.999-23.827-102.34-54.279-22.183-26.483-33.187-60.777-35.701-94.881z" ></path><path d="m661.51 139.06c13.74-14.056 24.27-31.148 30.562-49.773 6.3402 19.511 10.704 40.349 7.3837 60.872-2.7985 16.396-12.443 30.657-23.669 42.563 13.408-20.523 18.799-46.421 13.06-70.406-11.162 20.491-27.701 37.535-45.788 52.05-27.843 22.056-59.718 38.626-92.889 51.117-15.764 6.3402-32.728 8.775-48.618 14.736-30.958 10.672-60.477 27.1-83.26 50.911-21.076 21.661-35.496 49.393-42.357 78.77-7.6525 32.824-7.0992 67.37-0.0475 100.26-38.816-42.816-52.065-105.41-38.721-161.07 0.4901 25.55 0.7906 51.385 6.2769 76.477 2.0238 10.878 7.2889 20.681 13.424 29.756-1.4546-33.108 4.5377-66.88 19.811-96.446 22.957-45.504 66.358-79.244 115.04-93.284 34.436-9.6447 68.461-21.297 100.45-37.44 25.329-12.823 49.63-28.476 69.346-49.093z" ></path><path d="m397.2 136.96c51.654-16.728 106.72-20.728 160.67-17.06-37.203 3.5733-74.517 8.5063-110.31 19.637-54.532 16.364-105.02 44.808-148.94 80.857-32.586 24.38-67.291 47.29-106.64 59.085-33.219 10.372-68.303 13.155-102.94 12.048 32.238 20.301 71.07 29.456 109.02 27.005 14.04-0.506 27.638-4.2215 41.409-6.5615-27.78 10.404-58.01 13.566-87.418 10.024-53.71-6.0872-102.85-33.092-143.64-67.544 42.674 11.162 87.671 13.629 131.15 5.8026 53.662-9.3284 104.02-33.329 147.64-65.568 33.519-24.538 70.264-45.156 110.01-57.726z" ></path><path d="m822.89 198.97c-0.5533-2.1503-0.9328-4.3164-1.2965-6.4825 14.23 32.697 24.697 66.88 33.851 101.3 2.8618 11.463 6.0872 22.91 7.6683 34.642 0.2214 4.348 1.2806 9.1545-0.8538 13.202-4.0159 1.6443-8.5853 1.1384-12.728 2.4033 3.0831 7.0833 10.783 10.198 16.949 14.088-5.4864-0.3321-13.06-3.099-16.839 2.4348-2.8302 5.5338-2.514 12.08-4.5377 17.898-2.3085 7.9213-7.8423 15.653-16.19 17.724-8.949 2.5772-18.056-1.0435-25.598-5.7077-2.2609-1.7234-5.0594 0.7589-6.0872 2.7669-2.7827 5.1702-4.4745 10.83-7.0517 16.096 5.4865-26.657 13.882-54.88 34.594-73.837 5.3599-5.8658 15.321-6.7671 18.056-15.004 2.8301-9.0122 1.7708-18.768 0.7747-28.001-4.4903-31.653-12.301-62.722-20.712-93.521z" ></path><path d="m410.34 335.86c16.048-2.6088 32.539 3.5258 44.318 14.435 12.965 11.969 22.04 27.764 27.764 44.35-3.4468-3.9053-6.1821-10.83-12.301-10.404-8.1109 5.4231-16.87 11.716-27.132 11.162-7.605-0.6166-12.649-7.6208-14.23-14.546-2.3559-7.7631-0.1107-15.779-0.4269-23.653-0.7906-8.5853-10.53-10.372-15.953-15.258-1.4863-1.597-4.854-4.0951-2.0397-6.0873z" ></path><path d="m548.26 410.72c12.111 31.701 20.633 64.761 26.151 98.233 4.8223 30.578 7.2256 61.789 4.0634 92.668-2.2768-38.326-8.1901-76.303-14.878-114.06-4.6325-25.709-9.5971-51.354-15.336-76.841z" ></path><path d="m434.37 413.79c1.6759 54.105 2.4823 108.89 15.906 161.67 4.8539 17.882 10.894 36.286 23.479 50.342-17.787-7.3679-28.76-24.681-34.404-42.357-10.404-32.159-10.767-66.437-9.9767-99.909 0.5217-23.321 3.3677-46.484 4.9962-69.742z" ></path><path d="m730.3 421.19c0.5218-1.6285 1.0594-3.2412 1.5969-4.854-1.1226 8.949-4.4429 17.424-6.4034 26.214-12.206 49.915-19.653 101.02-22.119 152.34-4.4271-58.896 4.9172-118.88 26.926-173.7z" ></path><path d="m827.07 435.44c3.7155 36.998 5.771 74.374 1.4862 111.42-2.7037 23.906-7.6367 47.954-18.072 69.774-8.2217 14.277-18.847 27.005-27.416 41.077-14.166 22.262-23.685 47.622-26.452 73.948-0.6008 5.9607-0.9329 11.985-1.9132 17.93-4.3322-32.286 2.6405-65.315 16.681-94.47 5.4232-11.906 13.424-22.357 19.669-33.835 13.344-22.957 22.404-48.271 27.495-74.295 6.5299-33.345 8.364-67.449 7.9529-101.36 0.0157-3.3994 0.2686-6.8145 0.5691-10.182z" ></path><path d="m479.94 654.12c27.732 52.397 35.891 114.28 25.582 172.43-0.7905-7.2888-0.6008-14.609-0.8538-21.914-1.5178-51.006-11.494-101.38-24.728-150.52z" ></path><path d="m703.25 756.79c1.7866-2.8459 4.7591-5.3757 8.3798-4.269 5.0753 1.755 8.2217 6.7828 10.198 11.526 6.5457 19.827 11.542 40.207 14.262 60.919 1.9605 13.803 0.6323 28.365-5.2809 41.108-4.0634 8.696-12.127 16.032-21.946 17.076-16.412 2.0554-35.021-8.3007-38.658-25.092-2.6878-15.542 4.2689-31.337 14.483-42.784 9.4708-11.242 17.629-24.08 21.139-38.515 1.3597-6.6564 2.3241-14.467-2.5772-19.969z" ></path><path d="m538.63 756.53c2.4665-1.5496 6.2137-1.2491 7.9371 1.2964 4.6326 4.1267-2.0712 8.8542-1.502 13.629 0 13.977 7.9686 26.294 15.321 37.63 7.3679 11.542 19.115 20.68 22.183 34.61 2.9408 12.759-3.4626 25.519-11.953 34.705-7.6208 7.3837-19.242 9.8186-29.408 7.3362-8.4589-2.2451-15.289-8.7592-18.989-16.554-5.8184-12.206-6.0397-26.088-5.3915-39.322 1.1858-21.329 5.0595-42.879 14.309-62.279 2.1188-3.8735 3.8422-8.3321 7.4945-11.052z" ></path><path d="m744.37 879.14c0.079 10.087-2.3242 19.938-4.2373 29.788-3.4468 16.791-9.1545 33.867-20.997 46.69-14.91 16.475-36.808 24.159-58.073 28.302-26.42 4.8856-54.563 7.4628-80.256-2.1818-27.669-9.7869-49.077-32.412-62.137-58.184-5.9449-12.064-11.242-24.665-13.629-37.962 14.34 32.365 34.8 63.924 66.137 82.011-7.9213-7.526-14.451-16.301-20.554-25.313 23.195 17.265 51.132 30.041 80.556 29.329 28.254-0.0632 54.943-12.554 76.904-29.614-6.9252 10.894-17.36 18.783-26.436 27.764 20.95-7.2731 37.393-24.112 47.369-43.591 7.4628-14.752 12.918-30.658 15.352-47.038z" ></path></g>';

bytes constant DecaSVGLogo = '<g transform="matrix(0.140729, 0, 0, 0.140729, 77.470406, 60.887672)" style="filter: url(#convolve);"><path id="path1937" d="m 194.523,678.458 c 0,0 6.614,15.487 26.823,25.989 -36.209,-3.752 -36.209,-3.752 -108.809,-57.715 0,0 -3.961,43.834 -65.931,114.523 C 79.136,654.694 75.553,639.777 50.82,587.956 42.047,570.594 30.667,607.882 32.305,624.901 -29.53,420.944 186.221,344.222 186.221,344.222 l -44.287,-31.509 c 20.25595,6.62233 89.96962,3.75634 153.50245,-7.20475 13.73637,-2.36989 27.18381,-5.11819 39.77998,-8.23083 80.72363,-19.9476 126.48566,-54.85847 -10.72143,-101.02642 0,0 21.142,21.526 18.437,35.256 -4.628,-11.563 -19.559,-15.572 -19.559,-15.572 0,0 10.431,34.842 2.871,51.798 -2.607,-20.123 -35.243,-51.926 -35.243,-51.926 0,0 10.803,53.804 -84.81,50.951 -49.721,-2.147 -71.897,6.645 -88.816,23.42 -13.35,13.235 -16.599,15.452 -22.648,15.452 -6.99,0 -14.588,-4.41 -23.823,-13.827 -3.623,-3.694 -4.508,-6.947 -4.458,-16.388 0.054,-10.16 1.11,-13.324 7.682,-23.017 7.146,-10.539 8.701,-11.632 25.032,-17.595 9.577,-3.498 22.517,-8.674 28.755,-11.504 10.032,-4.55 11.571,-6.067 13.315,-13.132 2.102,-8.513 3.367,-9.416 28.241,-20.158 9.034,-3.902 16.433,-9.726 30.484,-23.992 16.791,-17.049 16.305,-21.761 16.742,-23.997 2.126,-28.576 -56.083,-0.082 -56.083,-0.082 0,0 12.359,-17.964 23.429,-25.727 30.092,-21.101 69.778,-1.523 69.778,-1.523 0,0 68.314,-77.578 165.77,-110.162 -4.705,3.168 -69.582,68.005 -68.519,75.294 13.397,0.29 20.538,7.561 20.538,7.561 -28.037,-1.063 -44.774,25.584 -44.774,25.584 12.987,-7.459 87.718,-18.98 87.718,-18.98 0,0 -10.271,6.69 -9.931,9.762 75.18,-21.638 232.268,-17.322 232.268,-17.322 -55.755,7.685 -163.767,48.154 -163.767,48.154 0,0 79.679,-5.803 125.542,10.257 -44.863,-2.393 -75.326,7.56 -90.639,15.867 58.441,31.073 98.813,129.557 98.813,129.557 0,0 -88.53,-96.203 -122.055,-86.197 0,0 122.684,184.38 14.609,257.953 5.074,-24.572 17.675,-115.897 -19.125,-135.901 -1.7e-4,1.1e-4 -101.13878,78.26401 -161.94176,103.99883 -7.89116,3.33993 -14.60839,6.58636 -20.85065,7.8402 -15.77675,3.16897 -30.17082,7.44327 -43.65559,7.12597 21.981,-7.636 29.573,-21.449 29.573,-21.449 -86.925,-18.187 -113.925,82.813 -96.56,121.846 -25.033,-9.032 -61.144,-53.433 -61.144,-53.433 0,0 5.718,99.022 126.081,85.045 -18.226,10.896 -44.637,22.022 -73.802,20.233 6.416,18.872 131.705,-2.4 139.458,-17.396 3.752,-7.254 21.614,-42.998 -22.813,-57.439 26.645,-14.168 68.57,39.254 68.57,39.254 0,0 7.797,-5.299 44.998,-11.798 37.201,-6.499 -26.332,-18.948 -26.332,-18.948 55.408,-0.583 81.521,9.249 81.521,9.249 9.138,-23.55 -103.337,-82.377 -103.337,-82.377 0,0 496.679,151.096 222.056,350.67 26.711,-67.76 26.813,-84.333 14.947,-119.558 -4.281,-12.708 -9.398,-22.516 -13.124,-25.152 -1.022,-0.723 3.722,8.785 -14.721,22.387 -24.225,-82.769 -127.818,-82.081 -138.267,-76.945 -57.126,22.426 0.696,58.563 26.624,44.009 -15.011,21.304 -58.09,21.02 -58.09,21.02 0,0 54.674,46.147 102.717,25.392 -31.543,77.256 -170.705,-49.23 -170.938,-49.651 -0.233,-0.421 -48.208,16.001 -48.208,16.001 0,0 62.426,51.938 92.265,155.797 C 307.138,721.445 194.523,678.458 194.523,678.458 z m 36.6,-486.846 c 20.22,-21.393 18.625,-24.149 -6.431,-11.109 -14.519,7.557 -39.887,21.442 -37.445,28.562 16.727,0.651 26.759,0.657 26.759,0.657 z" style="fill: #eeb32b;fill-opacity:1;stroke-width:6.20000029;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none"/></g>';

bytes constant OneSVGLogo = '<g transform="matrix(0.416557, 0, 0, 0.416557, 38.252357, 29.458517)" style="filter: url(#convolve);"><g transform="matrix(1, 0, 0, 1, -8.698837, -18.422098)" style="fill: #eeb32b;"> <path  d="M308.564,194.188c7.829-8.84,12.358-18.275,7.333-29.583 c-4.162-9.364-18.967-12.795-27.469-17.145c-3.662-1.873-9.201-4.916-9.198-9.605c0.002-2.231,2.834-4.218,2.834-6.583 c0-2.106-6.236-3.279-8.173-3.7c-9.3-2.022-24.055-5.523-33.13-1.438c-3.053,1.374,3.739,12.694-2.975,9.71 c-3.494-1.553-12.597-5.802-14.988-0.537c-6.261,13.778,12.134,13.383,21.151,13.383c10.643,0,24.419-0.689,33.614,5.5 c8.654,5.825,12.497,16.412,12.14,26.396c-0.2,5.611-0.993,9.504,4.916,11.802 C298.423,193.864,304.896,197.141,308.564,194.188" /><path  d="M211.897,127.688c-11.035,1.622-21.741,6.702-24.117,18.586 c-2.487,12.439,12.917,16.255,22.247,15.889c19.924-0.782,46.427-6.271,58.567,13.964c2.238,3.73,4.54,11.337,9.636,11.061 c6.191-0.336,5.5-8.626,4.334-13c-1.747-6.55-0.917-8.482-7.334-12.5c-4.7-2.942-9.48-4.646-15-5.667 c-11.232-2.079-23.057,0.75-34.078-2.292c-3.745-1.034-8.317-5.817-11.365-8.356c-5.407-4.506-6.926-7.176-3.278-13.661 C212.118,130.628,212.129,128.913,211.897,127.688" /><path  d="M258.564,326.855c-8.57-0.953-9.412,2.678-12.945,10.038 c-2.754,5.738-0.354,12.458,4.038,15.853c5.494,4.245,7.784-9.551,9.073-12.558 C260.435,336.211,264.577,327.375,258.564,326.855" /> <path  d="M241.73,315.521c-7.901,3.801-18.292,37.297-5.333,37.667 c3.229-6.588,1.262-14.581,4.25-21.25C242.176,328.527,249.316,316.126,241.73,315.521" /><path  d="M232.73,305.855c-8.072,7.636-13.016,18.079-17.729,27.932 c-2.478,5.181-3.3,29.569,8.297,21.383c6.913-4.88-0.442-19.805,1.349-27.231c1.238-5.135,4.185-9.426,7.658-13.334 C234.229,312.439,238.815,303.652,232.73,305.855" /><path  d="M298.897,245.188c1.469,4.539,2.523,8.752,4.906,12.883 c1.175,2.037,1.931,3.843,3.741,5.352c1.104,0.92,6.302-1.728,7.7-2.228c1.841-0.656,4.41,2.523,3.374,4.077 c-1.62,2.431-3.294,4.753-5.056,7.083c-2.833,3.747-5.718,10.601,1.5,6.167c7.549-4.637,15.459-15.187,9.34-23.142 C320.458,250.251,305.303,242.658,298.897,245.188" /><path  d="M301.73,294.688c-4.51-2.06-10.464-5.918-15.166-1.833 c-3.968,3.447-2.27,9.845-8.216,12.277c-12.324,5.041-20.498-12.478-13.186-21.08c3.389-3.987,8.384,6.893,9.796,8.957 c3.978,5.813,7.012-0.524,11.271-2.654c4.197-2.099,7.59-4.655,12.5-2.834C302.044,288.75,306.674,292.915,301.73,294.688" /><path  d="M 318.338 227.272 C 317.596 246.037 294.997 238.4 282.871 240.072 C 279.225 240.574 275.504 240.291 277.896 244.522 C 279.738 247.78 283.79 250.122 286.838 252.027 C 291.504 254.943 299.586 261.052 299.762 267.178 C 299.947 273.622 296.169 282.211 288.167 280.96 C 280.364 279.739 273.161 276.955 265.585 274.852 C 257.217 272.529 256.435 280.504 255.711 287.023 C 254.704 296.078 256.946 301.124 260.975 309.181 C 261.707 310.647 266.686 313.158 268.405 313.217 C 272.63 313.363 276.843 313.521 281.07 313.521 C 284.912 313.521 288.754 313.595 292.595 313.65 C 295.772 313.696 298.511 317.199 294.453 318.871 C 282.679 323.719 264.995 323.764 255.228 314.605 C 245.173 305.176 240.74 288.69 238.629 275.489 C 238.098 272.164 235.533 269.19 232.395 272.105 C 230.216 274.126 229.803 278.937 230.493 281.779 C 231.365 285.377 232.57 288.868 233.268 292.497 C 234.113 296.894 230.689 299.013 227.831 301.802 C 221.05 308.422 216.22 316.386 211.842 324.704 C 209.651 328.867 207.855 332.987 206.506 337.485 C 205.36 341.304 206.773 347.212 204.228 350.688 C 200.046 356.4 185.642 350.194 180.117 348.551 C 172.364 346.246 161.012 341.752 157.061 334.188 C 170.401 333.318 182.388 332.276 194.761 326.834 C 200.551 324.287 206.601 320.756 210.872 316.009 C 215.648 310.701 217.771 305.798 220.56 299.356 C 217.911 297.786 210.287 307.658 207.893 309.662 C 202.818 313.912 198.109 317.553 191.99 320.256 C 183.129 324.171 163.383 330.675 155.56 321.69 C 159.258 320.56 162.682 319.681 166.498 319.085 C 171.042 318.375 173.242 315.72 176.138 312.523 C 181.091 307.059 184.394 300.506 187.795 294.044 C 191.063 287.835 194.391 281.779 197.245 275.356 C 198.533 272.46 198.444 269.472 194.979 272.937 C 192.594 275.322 189.391 277.815 187.551 280.625 C 180.045 292.079 172.994 307.182 158.737 311.31 C 150.531 313.687 145.237 312.643 137.513 309.153 C 130.753 306.099 125.828 300.012 121.191 294.448 C 115.309 287.39 112.365 277.516 110.132 268.804 C 109.132 264.907 109.609 260.14 109.507 256.081 C 109.379 250.972 108.244 243.619 115.029 246.851 C 119.129 248.804 122.019 251.19 126.726 251.691 C 131.962 252.248 136.199 250.712 140.942 248.877 C 148.924 245.787 159.264 241.336 165.392 235.191 C 162.611 229.675 150.008 235.42 146.021 236.915 C 140.527 238.975 131.439 241.784 125.93 238.341 C 119.735 234.469 115.059 228.987 115.059 221.102 C 115.059 213.063 115.881 205.456 117.09 197.513 C 119.105 184.27 123.578 169.497 133.976 160.442 C 136.659 158.106 138.588 156.345 139.559 152.859 C 140.612 149.08 152.474 144.225 151.559 158.857 C 150.528 175.349 170.099 183.74 183.238 186.882 C 197.819 190.368 213.125 187.424 227.809 186.134 C 229.469 185.988 235.729 185.477 236.559 183.857 C 238.228 180.601 230.351 181.024 228.973 181.024 C 220.319 181.024 211.664 181.024 203.009 181.024 C 191.989 181.024 171.043 179.304 166.973 166.419 C 162.306 151.638 165.6 136.627 179.16 127.784 C 180.451 126.943 187.473 125.353 188.308 127.024 C 189.121 128.649 182.834 132.88 181.725 134.191 C 177.801 138.827 174.431 147.976 176.447 154.024 C 178.71 160.814 182.53 166.137 189.705 168.459 C 196.584 170.685 203.447 171.823 210.699 172.028 C 226.114 172.465 241.784 173.269 257.037 171.743 C 263.902 171.056 265.058 182.347 265.058 186.658 C 265.058 197.302 256.97 182.873 253.95 181.097 C 251.187 179.472 248.928 177.364 245.558 177.357 C 243.08 177.352 238.238 178.405 241.058 181.19 C 243.042 183.15 247.114 183.01 249.401 185.497 C 251.775 188.079 252.781 191.145 255.067 193.729 C 259.703 198.967 265.209 199.88 271.992 198.252 C 278.11 196.784 286.681 196.381 292.687 198.633 C 305.367 203.386 318.023 212.131 318.338 227.272 M 241.646 192.729 C 239.784 187.729 228.167 189.868 224.455 191.916 C 216.604 196.247 218.791 202.303 220.748 209.854 C 221.825 214.009 226.329 215.933 228.146 211.354 C 229.097 208.958 227.485 205.644 227.771 203.104 C 228.27 198.67 229.703 196.774 234.067 196.151 C 236.768 195.765 242.271 196.375 241.646 192.729 M 195.771 201.729 C 182.194 202.963 168.687 207.911 155.822 212.385 C 149.325 214.645 142.541 214.551 136.396 211.479 C 129.563 208.062 132.206 198.034 134.604 192.97 C 137.413 187.041 148.535 186.813 151.97 191.966 C 153.698 194.558 153.883 197.78 155.521 200.355 C 157.306 203.16 161.564 202.471 161.505 198.736 C 161.389 191.461 160.101 184.041 151.731 182.128 C 144.281 180.425 138.618 181.938 131.783 184.945 C 123.053 188.786 119.941 203.195 124.084 211.48 C 126.161 215.633 129.25 221.719 134.084 222.98 C 139.666 224.436 143.899 223.804 149.566 223.157 C 159.274 222.048 168.983 215.043 177.295 210.426 C 181.924 207.854 185.646 206.457 190.923 206.067 C 193.225 205.897 197.017 206.234 198.896 204.919 C 201.653 202.986 197.873 201.046 195.771 201.729 M 209.896 232.854 C 199.201 230.855 186.331 252.036 181.607 259.436 C 174.409 270.713 168.169 284.965 153.29 286.349 C 148.028 286.838 138.542 285.815 136.021 280.354 C 133.002 273.812 136.349 266.049 142.322 262.66 C 148.965 258.889 152.793 266.304 155.225 271.354 C 158.603 278.371 167.131 265.343 164.771 260.104 C 159.858 249.198 137.791 253.72 130.146 258.229 C 118.535 265.078 116.698 278.791 124.021 289.479 C 132.319 301.591 146.091 300.934 158.459 296.354 C 171.607 291.484 179.149 276.962 185.834 265.666 C 189.822 258.929 193.608 253.29 198.916 247.51 C 202.029 244.121 211.804 236.928 209.896 232.854 M 264.396 226.542 C 260.446 229.011 266.59 235.167 269.177 237.261 C 270.251 238.131 280.026 237.896 280.958 236.23 C 282.643 233.223 267.227 227.588 264.396 226.542" /></g></g>';








// File: @openzeppelin/contracts/utils/Base64.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/BiTSNFTURI.sol


// @author [email protected]
pragma solidity ^0.8.12;





contract BiTSNFTURI is Ownable {
    ContractMeta private _contractMeta;
   
    constructor (string memory name_, string memory description_, string memory depositSymbol_, string memory mintSymbol_) {
        _contractMeta = ContractMeta(name_,description_,depositSymbol_,mintSymbol_);
    }


    function buildImage(TokenMeta memory _tokenMeta, DepositUnits _depositUnit) private view returns (string memory)  {
        Seed memory _seed = generateSeed(_tokenMeta.tokenId, uint(_depositUnit) );
        SVGMeta memory _svgMeta = setMetaByUnit(_depositUnit);
        bytes memory _imgPrefix = generateImagePrefix(_seed);
        bytes memory _circlePrefix = abi.encodePacked(
            '<g><circle style="stroke-width: 3px; paint-order: stroke; stroke-miterlimit: 1; stroke-dasharray: 2; stroke-linecap: round; stroke-linejoin: round; stroke: ',
            _svgMeta.strokeHue,
            '; fill: ',
            _svgMeta.backgroundHue,
            ';" cx="125" cy="125" r="120"/><path d="M 235 125 C 235 64.249 185.751 15 125 15 C 64.249 15 15 64.249 15 125 C 15 185.751 64.249 235 125 235 C 185.751 235 235 185.751 235 125 Z" style="fill: none;" id="reversePath" />',
            '<path d="M 235 125 C 235 185.751 185.751 235 125 235 C 64.249 235 15 185.751 15 125 C 15 64.249 64.249 15 125 15 C 185.751 15 235 64.249 235 125 Z" style="fill: none;" id="frontPath"/>',
            '<path d="M 235 125 C 235 185.751 185.751 235 125 235 C 64.249 235 15 185.751 15 125 C 15 64.249 64.249 15 125 15 C 185.751 15 235 64.249 235 125 Z" style="fill: url(#a);"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 125 125" to="360 125 125" dur="200s" repeatCount="indefinite"></animateTransform></path></g>'

        );
        bytes memory _textPrefix = abi.encodePacked('<g style="fill: #eeb32b; font-family: Arial, sans-serif; font-size: 10px; font-weight: 700; text-anchor: middle; filter: url(#convolve);">',
                        META_TEXT_PREFIX,
                        _svgMeta.depositUnitInString);
        bytes memory _textSuffix = abi.encodePacked(' ',
                        _contractMeta.depositSymbol,
                        ' ',
                        Strings.toString(block.timestamp),
                        ' ',
                        Strings.toString(_tokenMeta.tokenId),
                        '</textPath></text>',
                        USER_TEXT_PREFIX,
                        _tokenMeta.userText,
                        '</textPath></text></g>',
                        UNIT_TEXT_PREFIX,
                        _svgMeta.depositUnitName,
                        '</text>',
                        _svgMeta.svgLogo,
                        '</svg>');
        return
            Base64.encode(
                bytes.concat(SVG_PREFIX, _imgPrefix, _circlePrefix, _textPrefix, _textSuffix)
            );
    }

    function createTokenURI(TokenMeta memory _tokenMeta, DepositUnits _depositUnit) public view onlyOwner returns(string memory) {
        bytes memory _metaPre = abi.encodePacked( '{"name":"',
                                _contractMeta.mintName,
                                '", "description":"',
                                _contractMeta.mintDescription,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(_tokenMeta, _depositUnit));
        bytes memory _metaAttr = abi.encodePacked('", "attributes": ',
                                "[",
                                '{"trait_type": "Mint Block",',
                                '"value":"',
                                Strings.toString(block.timestamp),
                                '"},',
                                '{"trait_type": "Mint Deposit",',
                                '"value":"',
                                Strings.toString(_tokenMeta.depositAmount),
                                '"},',
                                '{"trait_type": "Message",',
                                '"value":"',
                                _tokenMeta.userText,
                                '"}',
                                "]",
                                "}");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes.concat(_metaPre, _metaAttr)
                    )
                )
            );
    }


    function setMetaByUnit(DepositUnits _depositUnit) private pure returns(SVGMeta memory) {
    SVGMeta memory _svgMeta;
     if (DepositUnits.MILLI == _depositUnit) {
         _svgMeta.backgroundHue = "#8B8B8B";
         _svgMeta.strokeHue = "#4B4B4B";
         _svgMeta.depositUnitInString = "0.001";
         _svgMeta.depositUnitName = "MILLI";
         _svgMeta.svgLogo = "";
     }
     if (DepositUnits.CENTI == _depositUnit) {
         _svgMeta.backgroundHue = "#278AFF";
         _svgMeta.strokeHue = "#274A84";
         _svgMeta.depositUnitInString = "0.01";
         _svgMeta.depositUnitName = "CENTI";
         _svgMeta.svgLogo = "";
     }
     if (DepositUnits.DECI == _depositUnit) {
         _svgMeta.backgroundHue = "#DF6908";
         _svgMeta.strokeHue = "#763B11";
         _svgMeta.depositUnitInString = "0.1";
         _svgMeta.depositUnitName = "DECI";
         _svgMeta.svgLogo = "";
     }
     if (DepositUnits.ONE == _depositUnit) {
         _svgMeta.backgroundHue = "#FF4628";
         _svgMeta.strokeHue = "#931B0C";
         _svgMeta.depositUnitInString = "1";
         _svgMeta.depositUnitName = "";
         _svgMeta.svgLogo = OneSVGLogo;
     }
     if (DepositUnits.DECA == _depositUnit) {
         _svgMeta.backgroundHue = "#000000";
         _svgMeta.strokeHue = "#eeb32b";
         _svgMeta.depositUnitInString = "10";
         _svgMeta.depositUnitName = "";
         _svgMeta.svgLogo = DecaSVGLogo;
     }

     return _svgMeta;

    }

    function generateImagePrefix(Seed memory _seed) internal pure returns(bytes memory) {
        uint48 strokePatternHue2 = (_seed.strokePatternHue + 120) < 360 ? _seed.strokePatternHue + 120 : (_seed.strokePatternHue + 120) - 360;
        uint48 strokePatternHue3 = (strokePatternHue2 + 120) < 360 ? strokePatternHue2 + 120 : (strokePatternHue2 + 120) - 360;
        bytes memory _imagePrefix = abi.encodePacked(
            "<pattern id='a' patternUnits='userSpaceOnUse' width='40' height='60' patternTransform='scale(",
            Strings.toString(_seed.scale),
            ") rotate(",
            Strings.toString(_seed.rotate),
            ")'><g fill='none' stroke-width='",
            Strings.toString(_seed.strokeWidth),
            "'><path d='M-4.798 13.573C-3.149 12.533-1.446 11.306 0 10c2.812-2.758 6.18-4.974 10-5 4.183.336 7.193 2.456 10 5 2.86 2.687 6.216 4.952 10 5 4.185-.315 7.35-2.48 10-5 1.452-1.386 3.107-3.085 4.793-4.176'   stroke='hsla(",
            Strings.toString(_seed.strokePatternHue),
            ",50%,50%,1)'/><path d='M-4.798 33.573C-3.149 32.533-1.446 31.306 0 30c2.812-2.758 6.18-4.974 10-5 4.183.336 7.193 2.456 10 5 2.86 2.687 6.216 4.952 10 5 4.185-.315 7.35-2.48 10-5 1.452-1.386 3.107-3.085 4.793-4.176'  stroke='hsla(",
            Strings.toString(strokePatternHue2),
            ",35%,45%,1)' /><path d='M-4.798 53.573C-3.149 52.533-1.446 51.306 0 50c2.812-2.758 6.18-4.974 10-5 4.183.336 7.193 2.456 10 5 2.86 2.687 6.216 4.952 10 5 4.185-.315 7.35-2.48 10-5 1.452-1.386 3.107-3.085 4.793-4.176' stroke='hsla(",
            Strings.toString(strokePatternHue3),
            ",65%,55%,1)'/></g></pattern></defs>"
        );
        return _imagePrefix;
    }


    function generateSeed(uint256 tokenId, uint256 depositUnit) internal view returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, depositUnit))
        );

        uint48 scaleMax = 9;
        uint48 rotateMax = 360;
        uint48 strokeWidthMax = 9;
        uint48 hueMax = 360;
        uint48 saturationMax = 100;
        

        return Seed({
            scale: uint48(
                uint48(pseudorandomness >> 48) % scaleMax + 2
            ),
            rotate: uint48(
                uint48(pseudorandomness >> 96) % rotateMax
            ),
            strokeWidth: uint48(
                uint48(pseudorandomness >> 144) % strokeWidthMax + 2
            ),
            strokePatternHue: uint48(
                uint48(pseudorandomness >> 192) % hueMax
            ),         
            strokeSaturation: uint48(
                uint48(pseudorandomness >> 184) % saturationMax
            ),           
            strokeLightness: uint48(
                uint48(pseudorandomness >> 176) % saturationMax
            )
        });
    }

}


// File: contracts/BiTSNFTMint.sol


// @author [email protected]
pragma solidity ^0.8.4;








contract BiTSNFTMint is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {


    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId, string memory uri) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/BiTSNFTBank.sol


pragma solidity ^0.8.12;








/// @custom:security-contact [email protected]
contract BiTSNFTBank is Ownable {
    // Token Counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    // Deposit token
    IERC20Metadata public immutable depositToken;
    uint private immutable _depositTokenDecimals;
    // Mint and URI contracts
    BiTSNFTMint public immutable saMint;
    BiTSNFTURI public immutable saURI;
    uint public mintpremiumPct;
    // TokenId mappings
    mapping(uint256 => bytes32) public userTextHashToTokenId;
    mapping(uint256 => uint256) public depositAmountToTokenId;
    // Frontend URL
    string public webUrl = "https://bitsnft.xyz";
    //Events
    event MintTokenId(address indexed sender, uint256 tokenId);
    event BurnTokenId(address indexed sender, uint256 tokenId);

    constructor(address _depositToken, uint8 _premiumPercent, string memory _mintName, string memory _mintSymbol) {
        depositToken = IERC20Metadata(_depositToken);
        saMint = new BiTSNFTMint(_mintName, _mintSymbol);
        saURI = new BiTSNFTURI(_mintName, string.concat(_mintName,". Redeemable for ", depositToken.symbol()), depositToken.symbol(), _mintSymbol);
        _depositTokenDecimals = (10 ** depositToken.decimals());
        _premiumPercent <= 10? mintpremiumPct = _premiumPercent : mintpremiumPct = 10;
    }

    function setMintPremiumPct(uint8 _premiumPercent) public onlyOwner {
        _premiumPercent <= 10? mintpremiumPct = _premiumPercent : mintpremiumPct = 10;
    }

    function setWebUrl(string memory _webUrl) public onlyOwner {
        webUrl = _webUrl;
    }

    function mintDeposit(string memory _userText, DepositUnits _depositUnit) public returns(uint256){
        //Increment tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        //Get Unit. Set stringlimit and amount.
        require(uint8(_depositUnit) <= 4,"Choose btw 0 and 4");       
        uint256 _depositAmount;
        uint8 _stringLimit;
        if (DepositUnits.MILLI == _depositUnit) {
            _depositAmount =  _depositTokenDecimals/1000;
            _stringLimit = 4;
        } else if (DepositUnits.CENTI == _depositUnit) {
            _depositAmount = _depositTokenDecimals/100;
            _stringLimit = 8;
        } else if (DepositUnits.DECI == _depositUnit) {
            _depositAmount = _depositTokenDecimals/10;
            _stringLimit = 16;
        } else if (DepositUnits.ONE == _depositUnit) {
            _depositAmount =  _depositTokenDecimals;
            _stringLimit = 32;
        } else if (DepositUnits.DECA == _depositUnit) {
            _depositAmount = _depositTokenDecimals*10;
            _stringLimit = 60;
        } else {
            revert("Incorrect DepositUnit");
        }

        //Check user text not empty and within limits.
        require(bytes(_userText).length > 0, string.concat("Message string empty!"));
        require(bytes(_userText).length <= _stringLimit, string.concat("Max ",Strings.toString(_stringLimit)," chars!"));
        string memory _userTextUpper = toUpper(_userText);
        require(userTextExists(_userTextUpper) != true, "Text taken!");
        userTextHashToTokenId[tokenId] = keccak256(abi.encodePacked(_userTextUpper));        

        
        //msg.sender has to approve this contract to spend token first
        uint256 _mintPremium = (_depositAmount * mintpremiumPct)/100;
        uint256 _transferAmount = _depositAmount + _mintPremium;
        require(depositToken.allowance(msg.sender, address(this)) >= _transferAmount, "Check allowance");
        require(_transferAmount > 0,"Zero");

        //Store mapping of tokenid to depositamount
        depositAmountToTokenId[tokenId] = _depositAmount;

        //Transfer Deposit to Bank
        depositToken.transferFrom(msg.sender, address(this), _transferAmount);
        //Send Premium to Owner
        depositToken.transfer(owner(), _mintPremium);

        // Mint and Issue Deed
        TokenMeta memory _tokenMeta = TokenMeta(_userTextUpper, tokenId, _depositAmount);

        saMint.safeMint(msg.sender, tokenId, saURI.createTokenURI(_tokenMeta, _depositUnit));      
        // Emit event
        emit MintTokenId(msg.sender, tokenId);
        return tokenId;
    }

    
    function redeemDeposit(uint256 _tokenId) public {
        // Burn Deed
        //msg.sender has to approve this contract to burn token first

        //verify current token owner is calling
        require(msg.sender == saMint.ownerOf(_tokenId),"Not owner!");
        saMint.burn(_tokenId);
  
        //Refund Deposit
        require(depositAmountToTokenId[_tokenId] <= depositToken.balanceOf(address(this)), "Depleted!");
        depositToken.transfer(msg.sender, depositAmountToTokenId[_tokenId]);
        //remove usertext and deposit mapping
        delete userTextHashToTokenId[_tokenId];
        delete depositAmountToTokenId[_tokenId];
        //Emit event
        emit BurnTokenId(msg.sender, _tokenId);
   
    }

    function userTextExists(string memory _userTextUpper) public view returns (bool) {
        bool result = false;
        uint _totalSupply = _tokenIdCounter.current();

        for (uint256 i=0; i < _totalSupply; ++i) {
            if (
                userTextHashToTokenId[i] == keccak256(abi.encodePacked(_userTextUpper))
            ) {
                result = true;
            }
        }
        return result;
    }

    function toUpper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        uint length = _baseBytes.length;
        for (uint i=0; i < length; ++i) {
            if (_baseBytes[i] >= 0x61 && _baseBytes[i] <= 0x7A) {
                _baseBytes[i] = bytes1(uint8(_baseBytes[i]) - 32);
            }
        }
        return string(_baseBytes);
    }


}