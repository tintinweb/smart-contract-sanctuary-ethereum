//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Base64} from "./utils/Base64.sol";
import "./access/Ownable.sol";

import {ABDKMath64x64} from "./lib/ABDKMath64x64.sol";
import "./lib/Trigonometry.sol";

import "./interfaces/IMetadataRenderer.sol";
import "./interfaces/IERC721mini.sol";

///
import {Fixedpoint32x32} from "./Utils3D/Fixedpoint32x32.sol";

//
import "./SolidData.sol";
import "./TokenSettings.sol";

/**
 * @dev the following contract is a thought experiment of first 3d graphics rendering by Etherum,
 * for this experiment we nominateted platonic solids to render becuase they are a good benchmark
 * for validating rendering algorithm due to high degree of symetry, this implemntation is based on
 * painters algorithm and also have the capability to render in polygon mode and wireframe mode,
 * these objects are interactive and token owners can change the observer position of the rendering scene,
 * or change the polygon colors of their token, and someothere things.
 * for more info please visit https://OnChain3d.xyz
 */

contract OnChain3dMetadataRenderer is
    Ownable,
    IMetadataRenderer,
    SolidData,
    TokenSettings
{
    IERC721mini public targetContract;
    string private _contractURI;

    uint256 constant Pi = 3141592653589793238;
    //observer distance to projection plane = 1
    int128 constant dist = 18446744073709551616;
    // minimum_distance from solid object
    int128 private constant _minDistance = 64563604257983430656;
    //// svg header
    string private constant svgHead =
        '<svg width="1000" height="1000" viewBox="0 0 1000 1000" fill="none" xmlns="http://www.w3.org/2000/svg">';
    string private constant svgTail = "</svg>";
    // parts for rendering polygon svg

    string private constant p1 = '<polygon points="';
    string private constant p2 = '" fill="';

    string private constant p3 = '" opacity="0.';
    string private constant p4 = '" />';

    /// struct to carry data along the the {renderTokenById} and {previewTokenById} - too many stack too deep
    struct deepstruct {
        int128[3] _plane_normal;
        int128[3] _plane_vs_observer;
        int128[3] _center;
        int128[3] _observer;
        uint256[] _face_index;
        int128[] _projected_points_in_3d;
        int128[3] _z_prime;
        int128[3] _x_prime;
        int128[] _projected_points_in_2d;
        uint64[] pix0;
    }

    // struct to carry data along the the {svgPolygon}  to  cumpute polygon setting- too many stack too deep
    struct poly_struct {
        uint64[] pix;
        uint256[] sorted_index;
        uint8[] face_list;
        uint24[] color_list;
        uint8 opacity;
        uint8 polygon;
        bool face_or_wire;
        uint24 wire_color;
        uint24 back_color;
    }
    // struct to carry data inside the {scaledPoints}
    struct pix_struct {
        int128[] points_2d;
        int128[3] _observer;
        bool _dist_v_normalize;
    }

    constructor() {}

    function setTargetAddress(IERC721mini _targetAddress) public onlyOwner {
        targetContract = _targetAddress;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        _contractURI = _uri;
    }

    // see SolidData.sol
    function solidStruct_IMU(
        uint8 _tokenId,
        string calldata _name,
        uint256[] calldata _vertices,
        bytes calldata _face_list,
        uint8 _face_polygon
    ) public onlyOwner {
        SolidData.solidStruct(
            _tokenId,
            _name,
            _vertices,
            _face_list,
            _face_polygon
        );
    }

    // set setting see TokenSettings.sol
    function setMinimalSetting(
        uint256 id,
        int128[3] calldata _observer,
        uint256 _compressed,
        bytes calldata _colorlist
    ) public {
        // this function is only callable by token Owner
        require(
            targetContract.ownerOf(id) == msg.sender,
            "You must own the token"
        );
        require(
            _colorlist.length == number_of_faces[id % 5] * 3,
            "wrong number of colors"
        );
        require(
            opacityConverter(_compressed) < 100,
            "opacity should be less than 100"
        );
        int128[3] memory tempObserver = [_observer[0], _observer[1], int128(0)];
        int128 tempNorm = norm(tempObserver);
        require(tempNorm > _minDistance, "too close");
        //see TokenSettings.sol
        TokenSettings.setMinimal(id, _observer, _compressed, _colorlist);
    }

    // return the cross product of two vector
    function cross(
        int128[3] memory a,
        int128[3] memory b
    ) internal pure returns (int128[3] memory) {
        int128[3] memory d;
        d[0] = ABDKMath64x64.sub(
            ABDKMath64x64.mul(a[1], b[2]),
            ABDKMath64x64.mul(a[2], b[1])
        );
        d[1] = ABDKMath64x64.sub(
            ABDKMath64x64.mul(a[2], b[0]),
            ABDKMath64x64.mul(a[0], b[2])
        );
        d[2] = ABDKMath64x64.sub(
            ABDKMath64x64.mul(a[0], b[1]),
            ABDKMath64x64.mul(a[1], b[0])
        );
        return d;
    }

    // return the dot product of two vector
    function dot(
        int128[3] memory a,
        int128[3] memory b
    ) internal pure returns (int128) {
        int128 d = 0;
        d += ABDKMath64x64.mul(a[0], b[0]);
        d += ABDKMath64x64.mul(a[1], b[1]);
        d += ABDKMath64x64.mul(a[2], b[2]);
        return d;
    }

    // compute the norm of a vector
    function norm(int128[3] memory a) internal pure returns (int128) {
        return ABDKMath64x64.sqrt(dot(a, a));
    }

    // returns the vector ab , vector form point a to b, and return it as a fixed point 64x6x integer[3]
    function line_vector(
        int128[3] memory a,
        int128[3] memory b
    ) internal pure returns (int128[3] memory) {
        int128[3] memory d;

        d[0] = ABDKMath64x64.sub(b[0], a[0]);
        d[1] = ABDKMath64x64.sub(b[1], a[1]);
        d[2] = ABDKMath64x64.sub(b[2], a[2]);
        return d;
    }

    // compute the center of the Solid object
    function center(
        int128[3][] memory vertices0
    ) internal pure returns (int128[3] memory) {
        int128[3] memory d = [
            ABDKMath64x64.fromInt(0),
            ABDKMath64x64.fromInt(0),
            ABDKMath64x64.fromInt(0)
        ];
        uint256 len = vertices0.length;
        for (uint256 i = 0; i < len; i++) {
            d[0] = ABDKMath64x64.add(d[0], vertices0[i][0]);
            d[1] = ABDKMath64x64.add(d[1], vertices0[i][1]);
            d[2] = ABDKMath64x64.add(d[2], vertices0[i][2]);
        }
        d[0] = ABDKMath64x64.div(d[0], ABDKMath64x64.fromUInt(len));
        d[1] = ABDKMath64x64.div(d[1], ABDKMath64x64.fromUInt(len));
        d[2] = ABDKMath64x64.div(d[2], ABDKMath64x64.fromUInt(len));
        return d;
    }

    // compute the relative observer from the center of tthe Solid object and compute the rotation along z axis if need per 1 min
    function relative_observer(
        int128[3] memory observer0,
        int128[3] memory center0,
        uint256 angle_deg,
        bool rotating_mode
    ) internal view returns (int128[3] memory) {
        int128[3] memory d = [
            ABDKMath64x64.fromInt(0),
            ABDKMath64x64.fromInt(0),
            ABDKMath64x64.fromInt(0)
        ];

        if (rotating_mode) {
            uint256 tetha_rad = ((block.timestamp / 60) *
                (angle_deg % 360) *
                Pi) / 180;
            int128 si = ABDKMath64x64.div(
                ABDKMath64x64.fromInt(Trigonometry.sin(tetha_rad)),
                ABDKMath64x64.fromInt(1e18)
            );
            int128 cosi = ABDKMath64x64.div(
                ABDKMath64x64.fromInt(Trigonometry.cos(tetha_rad)),
                ABDKMath64x64.fromInt(1e18)
            );
            d = [
                dot([cosi, -si, 0], observer0),
                dot([si, cosi, 0], observer0),
                observer0[2]
            ];
        } else {
            d = observer0;
        }

        d[0] = ABDKMath64x64.add(d[0], center0[0]);
        d[1] = ABDKMath64x64.add(d[1], center0[1]);
        d[2] = ABDKMath64x64.add(d[2], center0[2]);

        return d;
    }

    // compute normal vector of the projection plane
    function plane_normal_vector(
        int128[3] memory relative_observer0,
        int128[3] memory center0
    ) internal pure returns (int128[3] memory) {
        int128[3] memory d;
        d = line_vector(relative_observer0, center0);
        int128 n = norm(d);
        d[0] = ABDKMath64x64.div(d[0], n);
        d[1] = ABDKMath64x64.div(d[1], n);
        d[2] = ABDKMath64x64.div(d[2], n);
        return d;
    }

    // middle point of the projection plane
    function plane_vs_observer(
        int128[3] memory relative_observer0,
        int128[3] memory plane_normal0
    ) internal pure returns (int128[3] memory) {
        int128[3] memory d = [
            ABDKMath64x64.fromInt(0),
            ABDKMath64x64.fromInt(0),
            ABDKMath64x64.fromInt(0)
        ];
        d[0] = ABDKMath64x64.add(
            relative_observer0[0],
            ABDKMath64x64.mul(dist, plane_normal0[0])
        );
        d[1] = ABDKMath64x64.add(
            relative_observer0[1],
            ABDKMath64x64.mul(dist, plane_normal0[1])
        );
        d[2] = ABDKMath64x64.add(
            relative_observer0[2],
            ABDKMath64x64.mul(dist, plane_normal0[2])
        );
        return d;
    }

    // points intersection with observer plane in 3d
    function projectedPointsIn3d(
        int128[3] memory relative_observer0,
        int128[3] memory plane_normal0,
        int128[3][] memory vertices0
    ) internal pure returns (int128[] memory) {
        int128[] memory _pointsIn3d = new int128[](vertices0.length * 3);

        int128[3] memory a;
        int128 t;
        for (uint256 i = 0; i < vertices0.length; i++) {
            a = line_vector(relative_observer0, vertices0[i]);

            t = dot(a, plane_normal0);
            _pointsIn3d[i * 3 + 0] = ABDKMath64x64.add(
                ABDKMath64x64.div(a[0], t),
                relative_observer0[0]
            );
            _pointsIn3d[i * 3 + 1] = ABDKMath64x64.add(
                ABDKMath64x64.div(a[1], t),
                relative_observer0[1]
            );
            _pointsIn3d[i * 3 + 2] = ABDKMath64x64.add(
                ABDKMath64x64.div(a[2], t),
                relative_observer0[2]
            );
        }

        return _pointsIn3d;
    }

    // point in projection plane with respect of Z_prime, X_prime as new coordinate system with origin at observer_vs_plane point
    function projectedPointsIn2d(
        int128[] memory points_3d,
        int128[3] memory z_prime0,
        int128[3] memory x_prime0,
        int128[3] memory observer_vs_plane0
    ) internal pure returns (int128[] memory) {
        uint256 len = (points_3d.length / 3);
        int128[] memory points_in_2d = new int128[](len * 2);
        for (uint256 i; i < len; i++) {
            points_in_2d[i * 2 + 0] = dot(
                line_vector(
                    observer_vs_plane0,
                    [
                        points_3d[i * 3 + 0],
                        points_3d[i * 3 + 1],
                        points_3d[i * 3 + 2]
                    ]
                ),
                x_prime0
            );
            points_in_2d[i * 2 + 1] = dot(
                line_vector(
                    observer_vs_plane0,
                    [
                        points_3d[i * 3 + 0],
                        points_3d[i * 3 + 1],
                        points_3d[i * 3 + 2]
                    ]
                ),
                z_prime0
            );
        }

        return points_in_2d;
    }

    // points scaled for the rendering from fixedpoint 64x64 to uint64, and normalization of the plane if neccesary
    function scaledPoints(
        pix_struct memory _pxs
    ) internal pure returns (uint64[] memory) {
        int128 mx0; // maximum of X coordinate

        uint16 _t = 500;
        int128 mx1; //maximum of Y coordinate
        int128 scale_factor;
        int128[] memory points_2d = _pxs.points_2d;
        mx0 = points_2d[0];
        mx1 = points_2d[1];
        uint64[] memory pix = new uint64[](points_2d.length);
        // assert(pix.length == 16);
        // return pix;
        for (uint256 i; i < (points_2d.length / 2); i++) {
            if (mx0 < points_2d[i * 2 + 0]) {
                mx0 = points_2d[i * 2 + 0];
            }
            if (mx1 < points_2d[i * 2 + 1]) {
                mx1 = points_2d[i * 2 + 1];
            }
        }
        if (mx0 < mx1) {
            mx0 = mx1;
        } // mx0 : maximum of X and Y coordinate

        if (_pxs._dist_v_normalize) {
            scale_factor = ABDKMath64x64.div(
                ABDKMath64x64.fromUInt(_t),
                norm(_pxs._observer)
            );
        } else {
            // scale_factor = ABDKMath64x64.fromUInt(_t);
            scale_factor = ABDKMath64x64.div(
                ABDKMath64x64.fromUInt(_t),
                ABDKMath64x64.fromUInt(2)
            );
        }
        // max(mx0 ,mx1) mx
        for (uint256 i; i < (points_2d.length / 2); i++) {
            pix[i * 2 + 0] = ABDKMath64x64.toUInt(
                ABDKMath64x64.add(
                    ABDKMath64x64.div(
                        ABDKMath64x64.mul(points_2d[i * 2 + 0], scale_factor),
                        mx0
                    ),
                    ABDKMath64x64.fromUInt(_t)
                )
            );
            pix[i * 2 + 1] = ABDKMath64x64.toUInt(
                ABDKMath64x64.add(
                    ABDKMath64x64.div(
                        ABDKMath64x64.mul(points_2d[i * 2 + 1], scale_factor),
                        mx0
                    ),
                    ABDKMath64x64.fromUInt(_t)
                )
            );
        }
        return pix;
    }

    // poject vector (0,0,-1) to the plane
    function z_prime(
        int128[3] memory plane_normal0
    ) internal pure returns (int128[3] memory) {
        int128[3] memory z = [
            ABDKMath64x64.fromInt(0),
            ABDKMath64x64.fromInt(0),
            ABDKMath64x64.fromInt(-1)
        ];
        //svg has left handed coordinate system hence -z
        int128[3] memory z_p;
        int128 nz;
        int128 dz;
        dz = dot(z, plane_normal0);
        z_p[0] = ABDKMath64x64.sub(
            z[0],
            ABDKMath64x64.mul(dz, plane_normal0[0])
        );
        z_p[1] = ABDKMath64x64.sub(
            z[1],
            ABDKMath64x64.mul(dz, plane_normal0[1])
        );
        z_p[2] = ABDKMath64x64.sub(
            z[2],
            ABDKMath64x64.mul(dz, plane_normal0[2])
        );
        nz = norm(z_p);
        z_p[0] = ABDKMath64x64.div(z_p[0], nz);
        z_p[1] = ABDKMath64x64.div(z_p[1], nz);
        z_p[2] = ABDKMath64x64.div(z_p[2], nz);

        return z_p;
    }

    // cross Z-prime with plane normal to find a perpendicular vetor to z_prime, inside the plane
    function x_prime(
        int128[3] memory plane_normal0,
        int128[3] memory z_prime0
    ) internal pure returns (int128[3] memory) {
        return cross(z_prime0, plane_normal0);
    }

    // depth sorting face polygons to be rendered
    function face_index(
        int128[3] memory relative_observer0,
        int128[3][] memory vertices0,
        uint8[] memory face_list0,
        uint8 polygon0
    ) internal pure returns (uint256[] memory) {
        uint256 face_list_length0 = face_list0.length / polygon0;
        int128[] memory df = new int128[](face_list_length0);
        int128 mx;
        uint256 mxi;
        uint256[] memory sorted_index = new uint256[](face_list_length0);

        for (uint256 i; i < face_list_length0; i++) {
            for (uint256 j; j < polygon0; j++) {
                mx = norm(
                    line_vector(
                        vertices0[face_list0[i * polygon0 + j]],
                        relative_observer0
                    )
                );
                df[i] = ABDKMath64x64.add(df[i], mx);
            }
        }
        mx = 0; // delete mx value
        for (uint256 i; i < face_list_length0; i++) {
            for (uint256 j; j < face_list_length0; j++) {
                if (mx < df[j]) {
                    mx = df[j];
                    mxi = j;
                }
            }
            delete df[mxi];
            // df[mxi]
            sorted_index[i] = mxi;
            mx = 0;
        }
        return sorted_index;
    }

    // rendering token SVG with the polygon setting (face)
    function svgPolygon(
        poly_struct memory pls0
    ) internal pure returns (string memory) {
        // uint
        string memory a = string(
            abi.encodePacked(
                '<rect x="0" y="0" width="1000" height="1000" fill="#',
                toHexString(pls0.back_color, 3),
                '" /><g stroke="#',
                toHexString(pls0.wire_color, 3),
                '" stroke-width="1.42" stroke-opacity="0.69">'
            )
        );
        uint8[] memory face_list0 = pls0.face_list;
        uint8 _polygon = pls0.polygon;
        uint256 face_list_length0 = face_list0.length / _polygon;
        uint24 color;
        uint24[] memory color_list0 = pls0.color_list;
        uint64[] memory pix0 = pls0.pix;
        string memory opacityStr = string(
            abi.encodePacked(
                uint2str(pls0.opacity / 10),
                uint2str(pls0.opacity % 10)
            )
        );

        uint256[] memory sorted_index0 = pls0.sorted_index;
        uint256 t = 0;
        uint256 t2 = 0;
        uint64 x0 = 0;
        uint64 y0 = 0;

        for (uint256 i = 0; i < face_list_length0; i++) {
            a = string(abi.encodePacked(a, p1));

            color = color_list0[sorted_index0[i]];
            t = sorted_index0[i];

            for (uint256 j; j < _polygon; j++) {
                t2 = face_list0[t * _polygon + j] * 2;
                x0 = pix0[t2];
                // x0 = 0;
                y0 = pix0[t2 + 1];

                a = string(abi.encodePacked(a, uint2str(x0), ","));
                a = string(abi.encodePacked(a, uint2str(y0), " "));
            }
            if (pls0.face_or_wire) {
                a = string(
                    abi.encodePacked(a, p2, "#", toHexString(color, 3), p3)
                );
            } else {
                a = string(abi.encodePacked(a, p2, "none", p3));
            }
            a = string(abi.encodePacked(a, opacityStr, p4));
        }

        return string(abi.encodePacked(a, "</g>"));
    }

    // preparing setting of token for {previewTokenById}
    function preSetting(
        uint256 id,
        int128[3] calldata _observer,
        uint256 _compressed,
        bytes calldata _colorlist
    ) internal view returns (GeneralSetting memory) {
        require(
            _colorlist.length == number_of_faces[id % 5] * 3,
            "wrong number of colors"
        );
        require(
            opacityConverter(_compressed) < 100,
            "opacity should be less than 100"
        );
        uint256 _packObserver;
        int128[3] memory tempObserver = [_observer[0], _observer[1], int128(0)];
        int128 tempNorm = norm(tempObserver);
        require(tempNorm > _minDistance, "too close");
        unchecked {
            _packObserver =
                (_compressed << 192) |
                Fixedpoint32x32.packVector(_observer);
        }
        return minimalToGeneral(MinimalSetting(_packObserver, _colorlist));
    }

    //for preview the tokenSVG with new setting, see EIP-4883
    function previewTokenById(
        uint256 tid,
        int128[3] calldata _observerP,
        uint256 _compressedP,
        bytes calldata _colorlistP
    ) public view returns (string memory) {
        // Solid memory _solid = num2solid[tid % 5];getUnPackedSolid
        Solid memory _solid = getUnPackedSolid(tid % 5);
        GeneralSetting memory _generalSetting = preSetting(
            tid,
            _observerP,
            _compressedP,
            _colorlistP
        );

        pix_struct memory pxs;
        poly_struct memory pls;
        deepstruct memory _deepstruct;

        int128[3] memory _observer = _generalSetting.observer;
        _deepstruct._center = center(_solid.vertices);

        _observer = relative_observer(
            _observer,
            _deepstruct._center,
            _generalSetting.angular_speed_deg,
            _generalSetting.rotating_mode
        );
        _deepstruct._plane_normal = plane_normal_vector(
            _observer,
            _deepstruct._center
        );
        _deepstruct._plane_vs_observer = plane_vs_observer(
            _observer,
            _deepstruct._plane_normal
        );

        _deepstruct._z_prime = z_prime(_deepstruct._plane_normal);
        _deepstruct._x_prime = x_prime(
            _deepstruct._plane_normal,
            _deepstruct._z_prime
        );

        _deepstruct._projected_points_in_3d = projectedPointsIn3d(
            _observer,
            _deepstruct._plane_normal,
            _solid.vertices
        );

        _deepstruct._projected_points_in_2d = projectedPointsIn2d(
            _deepstruct._projected_points_in_3d,
            _deepstruct._z_prime,
            _deepstruct._x_prime,
            _deepstruct._plane_vs_observer
        );
        pxs.points_2d = _deepstruct._projected_points_in_2d;
        pxs._observer = _observer;
        pxs._dist_v_normalize = _generalSetting.dist_v_normalize;

        _deepstruct.pix0 = scaledPoints(pxs);

        _deepstruct._face_index = face_index(
            _observer,
            _solid.vertices,
            _solid.face_list,
            _solid.face_polygon
        );

        pls.pix = _deepstruct.pix0;
        pls.face_list = _solid.face_list;
        pls.color_list = _generalSetting.color_list;
        pls.sorted_index = _deepstruct._face_index;
        pls.opacity = _generalSetting.opacity;
        pls.polygon = _solid.face_polygon;
        pls.wire_color = _generalSetting.wire_color;
        pls.face_or_wire = _generalSetting.face_or_wire;
        pls.back_color = _generalSetting.back_color;

        return svgPolygon(pls);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory _svg = string(
            abi.encodePacked(svgHead, (renderTokenById(tokenId)), svgTail)
        );
        string memory _metadataTop = string(
            abi.encodePacked(
                '{"description": "interactive 3D objects fully on-chain, rendered by Etherum.", "name": "',
                getSolidName(tokenId % 5),
                " ",
                uint2str(tokenId / 5),
                '" ,"attributes": [{"display_type": "number", "trait_type": "tokenId", "value": ',
                uint2str(tokenId),
                '},{"trait_type": "polyhydron", "value": "',
                getSolidName(tokenId % 5),
                '"}]'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                _metadataTop,
                                '  , "image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(_svg)),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    // for more detail see EIP-4883, renderTokenById -- Too many stack too deep see
    function renderTokenById(uint256 tid) public view returns (string memory) {
        // Solid memory _solid = num2solid[tid % 5];getUnPackedSolid
        Solid memory _solid = getUnPackedSolid(tid % 5);

        // GeneralSetting memory _generalSetting = generalSettings[tid];
        GeneralSetting memory _generalSetting;
        bool b;
        (b, _generalSetting) = getGeneralSetting(tid);

        //structs to carry data - to avoid stack too deep
        pix_struct memory pxs;
        deepstruct memory _deepstruct;
        poly_struct memory pls;

        int128[3] memory _observer = _generalSetting.observer;
        _deepstruct._center = center(_solid.vertices);
        // relative observer with respect to center of the Solid object
        _observer = relative_observer(
            _observer,
            _deepstruct._center,
            _generalSetting.angular_speed_deg,
            _generalSetting.rotating_mode
        );
        // projection plane normal vector
        _deepstruct._plane_normal = plane_normal_vector(
            _observer,
            _deepstruct._center
        );
        // new origin in the projection plane
        _deepstruct._plane_vs_observer = plane_vs_observer(
            _observer,
            _deepstruct._plane_normal
        );
        // z_prime , normalize projection of (0,0,-1) uint vector to projection plane
        _deepstruct._z_prime = z_prime(_deepstruct._plane_normal);
        // cross product of z_prime with plane normal to get the perpendicular vector inside the projection plane
        _deepstruct._x_prime = x_prime(
            _deepstruct._plane_normal,
            _deepstruct._z_prime
        );
        // projected point onto projection plane in 3d
        _deepstruct._projected_points_in_3d = projectedPointsIn3d(
            _observer,
            _deepstruct._plane_normal,
            _solid.vertices
        );
        //  projection points onto the plane in 2d
        _deepstruct._projected_points_in_2d = projectedPointsIn2d(
            _deepstruct._projected_points_in_3d,
            _deepstruct._z_prime,
            _deepstruct._x_prime,
            _deepstruct._plane_vs_observer
        );
        pxs.points_2d = _deepstruct._projected_points_in_2d;
        pxs._observer = _observer;
        pxs._dist_v_normalize = _generalSetting.dist_v_normalize;
        // scaling the points and removing decimal point
        _deepstruct.pix0 = scaledPoints(pxs);

        _deepstruct._face_index = face_index(
            _observer,
            _solid.vertices,
            _solid.face_list,
            _solid.face_polygon
        );

        pls.pix = _deepstruct.pix0;
        pls.face_list = _solid.face_list;
        pls.color_list = _generalSetting.color_list;
        pls.sorted_index = _deepstruct._face_index;
        pls.opacity = _generalSetting.opacity;
        pls.polygon = _solid.face_polygon;
        pls.wire_color = _generalSetting.wire_color;
        pls.face_or_wire = _generalSetting.face_or_wire;
        pls.back_color = _generalSetting.back_color;

        return svgPolygon(pls);
    }

    function uint2str(
        uint256 _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    //needs check
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes16 _SYMBOLS = "0123456789abcdef";
        bytes memory buffer = new bytes(2 * length);
        // buffer[0] = "0";
        // buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i - 2] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function initializeWithData(bytes memory) public pure {
        revert("not callable");
    }
}

//SPDX-License-Identifier: MIT

import {Fixedpoint32x32} from "./Utils3D/Fixedpoint32x32.sol";

pragma solidity ^0.8.0;

abstract contract TokenSettings {
    struct GeneralSetting {
        int128[3] observer;
        uint24 back_color;
        uint24 wire_color;
        uint16 angular_speed_deg;
        uint8 opacity;
        bool rotating_mode;
        bool dist_v_normalize;
        bool face_or_wire;
        uint24[] color_list;
    }

    struct MinimalSetting {
        uint256 observer; //packeSettingAndObserver;
        bytes colorlist;
    }

    uint256 private constant packedDefaultObserver =
        0x00ff6699001f4505000000040000000000000004000000000000000100000000;
    // uint256 private constant defaultCompressed = 71888926379296005;
    bytes private constant defaultColorlist =
        hex"ffc300e74c3c3498db2ecc719b59b6f1c40f27ae602980b98e44adf39c12c0392b1abc9c34495e7f8c8d16a085d35400bdc3c72c3e50f0e68cf5b041";

    // tokenId -> MinimalSetting
    mapping(uint256 => MinimalSetting) private minimalSettings;

    // a  function to unpack the packed data of minimal setting to general setting
    function minimalToGeneral(
        MinimalSetting memory _minimal
    ) internal pure returns (GeneralSetting memory) {
        uint256 _comp = _minimal.observer >> 192;
        int128[3] memory _observer = Fixedpoint32x32.unPackVector(
            _minimal.observer
        );
        return
            GeneralSetting({
                observer: _observer,
                opacity: opacityConverter(_comp),
                rotating_mode: rotating_modeConverter(_comp),
                angular_speed_deg: angular_speed_degConverter(_comp),
                dist_v_normalize: dist_v_normalizeConverter(_comp),
                face_or_wire: face_or_wiretConverter(_comp),
                back_color: back_colorConverter(_comp),
                wire_color: wire_colorConverter(_comp),
                color_list: color_listConverter(_minimal.colorlist)
            });
    }

    // set setting
    function setMinimal(
        uint256 id,
        int128[3] calldata _observer,
        uint256 _compressed,
        bytes calldata _colorlist
    ) internal {
        uint256 _packObserver;
        unchecked {
            _packObserver =
                (_compressed << 192) |
                Fixedpoint32x32.packVector(_observer);
        }

        minimalSettings[id] = MinimalSetting(_packObserver, _colorlist);
    }

    // retrive setting
    function getGeneralSetting(
        uint256 id
    ) public view returns (bool, GeneralSetting memory) {
        bool isDefault;
        MinimalSetting memory _minimalSetting = minimalSettings[id];
        int128[3] memory _observer = Fixedpoint32x32.unPackVector(
            _minimalSetting.observer
        );
        if (_observer[0] == 0 && _observer[1] == 0) {
            isDefault = true;
            // return (isDefault, defaultSetting);
            return (
                isDefault,
                minimalToGeneral(
                    MinimalSetting(packedDefaultObserver, defaultColorlist)
                )
            );
        } else {
            isDefault = false;
            return (isDefault, minimalToGeneral(_minimalSetting));
        }
    }

    function getMinimalSetting(
        uint256 id
    ) public view returns (bool, MinimalSetting memory) {
        bool isDefault;
        MinimalSetting memory _minimalSetting = minimalSettings[id];
        int128[3] memory _observer = Fixedpoint32x32.unPackVector(
            _minimalSetting.observer
        );
        if (_observer[0] == 0 && _observer[1] == 0) {
            isDefault = true;
            return (isDefault, _minimalSetting);
        } else {
            isDefault = false;
            return (isDefault, _minimalSetting);
        }
    }

    function opacityConverter(uint256 compressd) internal pure returns (uint8) {
        unchecked {
            return uint8((compressd >> 8) & 0xff);
        }
    }

    function rotating_modeConverter(
        uint256 compressd
    ) internal pure returns (bool) {
        unchecked {
            return (compressd & 1) == 1;
        }
    }

    function angular_speed_degConverter(
        uint256 compressd
    ) internal pure returns (uint16) {
        unchecked {
            return uint16((compressd >> 16) & 0xffff);
        }
    }

    function dist_v_normalizeConverter(
        uint256 compressd
    ) internal pure returns (bool) {
        unchecked {
            return (compressd & 2) == 2;
        }
    }

    function face_or_wiretConverter(
        uint256 compressd
    ) internal pure returns (bool) {
        unchecked {
            return (compressd & 4) == 4;
        }
    }

    function wire_colorConverter(
        uint256 compressd
    ) internal pure returns (uint24) {
        unchecked {
            return uint24((compressd >> 32) & 0xffffff);
        }
    }

    function back_colorConverter(
        uint256 compressd
    ) internal pure returns (uint24) {
        unchecked {
            return uint24((compressd >> 56) & 0xffffff);
        }
    }

    function color_listConverter(
        bytes memory colorlist
    ) internal pure returns (uint24[] memory) {
        uint256 len = colorlist.length;
        uint24[] memory _colors = new uint24[](len / 3);
        for (uint256 i; i < len / 3; i++) {
            unchecked {
                _colors[i] = uint24(
                    bytesToUint(
                        abi.encodePacked(
                            colorlist[i * 3],
                            colorlist[i * 3 + 1],
                            colorlist[i * 3 + 2]
                        )
                    )
                );
            }
        }
        return _colors;
    }

    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        for (uint256 i = 0; i < b.length; i++) {
            number =
                number +
                uint256(uint8(b[i])) *
                (2 ** (8 * (b.length - (i + 1))));
        }
        return number;
    }
}

//SPDX-License-Identifier: MIT

import {Fixedpoint32x32} from "./Utils3D/Fixedpoint32x32.sol";

pragma solidity ^0.8.0;

abstract contract SolidData {
    struct Solid {
        string name;
        int128[3][] vertices;
        uint8[] face_list;
        uint8 face_polygon;
    }
    struct PackedSolid {
        uint256[] vertices;
        bytes face_list;
        string name;
        uint8 face_polygon;
    }
    uint256[5] internal number_of_faces = [4, 6, 8, 12, 20];

    // five Solid
    mapping(uint256 => PackedSolid) private num2PackedSolid;

    // uploading data of the 5 platonic Solid
    function solidStruct(
        uint8 _tokenId,
        string calldata _name,
        uint256[] calldata _vertices,
        bytes calldata _face_list,
        uint8 _face_polygon
    ) internal {
        num2PackedSolid[_tokenId].name = _name;
        num2PackedSolid[_tokenId].vertices = _vertices;
        num2PackedSolid[_tokenId].face_list = _face_list;
        num2PackedSolid[_tokenId].face_polygon = _face_polygon;
    }

    function getUnPackedSolid(
        uint256 _solidNumber
    ) public view returns (Solid memory) {
        PackedSolid memory _PS = num2PackedSolid[_solidNumber];
        uint256 _len = _PS.vertices.length;
        uint256 _faceLen = number_of_faces[_solidNumber] * _PS.face_polygon;
        uint8[] memory _fl = new uint8[](_faceLen);
        int128[3][] memory _vertices = new int128[3][](_len);
        for (uint56 i = 0; i < _len; i++) {
            uint256 tempUnit = _PS.vertices[i];

            _vertices[i] = Fixedpoint32x32.unPackVector(tempUnit);
        }
        for (uint256 j = 0; j < _faceLen; j++) {
            _fl[j] = uint8(_PS.face_list[j]);
        }
        return Solid(_PS.name, _vertices, _fl, _PS.face_polygon);
    }

    function getSolidName(
        uint256 _solidNumber
    ) internal view returns (string memory) {
        return num2PackedSolid[_solidNumber].name;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Fixedpoint32x32 {
    /**
     * @dev convert packed vector 3 signed fixedpoint32x32 as uint256 to array of fixedpoint64x64 in int128[3]
     * Bits Layout:
     * - [0..63]   `z in fixedpoint32x32`
     * - [64..127] `y in fixedpoint32x32`
     * - [128..191]  `x in fixedpoint32x32`
     * - [192..255]  `0`
     * -
     */
    function unPackVector(
        uint256 _packedVector
    ) internal pure returns (int128[3] memory) {
        int128[3] memory _unpackedVector;

        unchecked {
            _unpackedVector[2] =
                int128(int64(uint64(_packedVector & uint256(2 ** 64 - 1)))) *
                2 ** 32;
            _packedVector = _packedVector >> 64;
            _unpackedVector[1] =
                int128(int64(uint64(_packedVector & uint256(2 ** 64 - 1)))) *
                2 ** 32;
            _packedVector = _packedVector >> 64;
            _unpackedVector[0] =
                int128(int64(uint64(_packedVector & uint256(2 ** 64 - 1)))) *
                2 ** 32;
        }

        return _unpackedVector;
    }

    function packVector(
        int128[3] memory _unPackedVector
    ) internal pure returns (uint256) {
        // uint256 packedVector;
        // unchecked {
        //     packedVector = uint256(uint128(_unPackedVector[0] / 2 ** 32)) >> 32;
        //     packedVector = packedVector << 64;
        //     packedVector = uint256(uint128(_unPackedVector[1] / 2 ** 32)) >> 32;
        //     packedVector = packedVector << 64;
        //     packedVector = uint256(uint128(_unPackedVector[2] / 2 ** 32)) >> 32;
        // }
        // return packedVector;
        uint256 packedVector;
        unchecked {
            packedVector = fixedpoint64x64to32x32(_unPackedVector[0]);
            packedVector = packedVector << 64;
            packedVector = fixedpoint64x64to32x32(_unPackedVector[1]);
            packedVector = packedVector << 64;
            packedVector = fixedpoint64x64to32x32(_unPackedVector[2]);
        }
        return packedVector;
    }

    function fixedpoint64x64to32x32(
        int128 _fixedpoint64x64Number
    ) internal pure returns (uint256) {
        uint256 _fixedpoint32x32Number;
        unchecked {
            _fixedpoint32x32Number =
                uint256(uint128(_fixedpoint64x64Number / 2 ** 32)) >>
                32;
        }
        return _fixedpoint32x32Number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721mini {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);

    function contractURI() external view returns (string memory);

    function initializeWithData(bytes memory initData) external;
}

//SPDX-License-Identifier: MIT
/**
 * @notice Solidity library offering basic trigonometry functions where inputs and outputs are
 * integers. Inputs are specified in radians scaled by 1e18, and similarly outputs are scaled by 1e18.
 *
 * This implementation is based off the Solidity trigonometry library written by Lefteris Karapetsas
 * which can be found here: https://github.com/Sikorkaio/sikorka/blob/e75c91925c914beaedf4841c0336a806f2b5f66d/contracts/trigonometry.sol
 *
 * Compared to Lefteris' implementation, this version makes the following changes:
 *   - Uses a 32 bits instead of 16 bits for improved accuracy
 *   - Updated for Solidity 0.8.x
 *   - Various gas optimizations
 *   - Change inputs/outputs to standard trig format (scaled by 1e18) instead of requiring the
 *     integer format used by the algorithm
 *
 * Lefertis' implementation is based off Dave Dribin's trigint C library
 *     http://www.dribin.org/dave/trigint/
 *
 * Which in turn is based from a now deleted article which can be found in the Wayback Machine:
 *     http://web.archive.org/web/20120301144605/http://www.dattalo.com/technical/software/pic/picsine.html
 */

pragma solidity ^0.8.0;

library Trigonometry {
    // Table index into the trigonometric table
    uint256 constant INDEX_WIDTH = 8;
    // Interpolation between successive entries in the table
    uint256 constant INTERP_WIDTH = 16;
    uint256 constant INDEX_OFFSET = 28 - INDEX_WIDTH;
    uint256 constant INTERP_OFFSET = INDEX_OFFSET - INTERP_WIDTH;
    uint32 constant ANGLES_IN_CYCLE = 1073741824;
    uint32 constant QUADRANT_HIGH_MASK = 536870912;
    uint32 constant QUADRANT_LOW_MASK = 268435456;
    uint256 constant SINE_TABLE_SIZE = 256;

    // Pi as an 18 decimal value, which is plenty of accuracy: "For JPL's highest accuracy calculations, which are for
    // interplanetary navigation, we use 3.141592653589793: https://www.jpl.nasa.gov/edu/news/2016/3/16/how-many-decimals-of-pi-do-we-really-need/
    uint256 constant PI = 3141592653589793238;
    uint256 constant TWO_PI = 2 * PI;
    uint256 constant PI_OVER_TWO = PI / 2;

    // The constant sine lookup table was generated by generate_trigonometry.py. We must use a constant
    // bytes array because constant arrays are not supported in Solidity. Each entry in the lookup
    // table is 4 bytes. Since we're using 32-bit parameters for the lookup table, we get a table size
    // of 2^(32/4) + 1 = 257, where the first and last entries are equivalent (hence the table size of
    // 256 defined above)
    uint8 constant entry_bytes = 4; // each entry in the lookup table is 4 bytes
    uint256 constant entry_mask = ((1 << (8 * entry_bytes)) - 1); // mask used to cast bytes32 -> lookup table entry
    bytes constant sin_table =
        hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";

    /**
     * @notice Return the sine of a value, specified in radians scaled by 1e18
     * @dev This algorithm for converting sine only uses integer values, and it works by dividing the
     * circle into 30 bit angles, i.e. there are 1,073,741,824 (2^30) angle units, instead of the
     * standard 360 degrees (2pi radians). From there, we get an output in range -2,147,483,647 to
     * 2,147,483,647, (which is the max value of an int32) which is then converted back to the standard
     * range of -1 to 1, again scaled by 1e18
     * @param _angle Angle to convert
     * @return Result scaled by 1e18
     */
    function sin(uint256 _angle) internal pure returns (int256) {
        unchecked {
            // Convert angle from from arbitrary radian value (range of 0 to 2pi) to the algorithm's range
            // of 0 to 1,073,741,824
            _angle = (ANGLES_IN_CYCLE * (_angle % TWO_PI)) / TWO_PI;

            // Apply a mask on an integer to extract a certain number of bits, where angle is the integer
            // whose bits we want to get, the width is the width of the bits (in bits) we want to extract,
            // and the offset is the offset of the bits (in bits) we want to extract. The result is an
            // integer containing _width bits of _value starting at the offset bit
            uint256 interp = (_angle >> INTERP_OFFSET) &
                ((1 << INTERP_WIDTH) - 1);
            uint256 index = (_angle >> INDEX_OFFSET) & ((1 << INDEX_WIDTH) - 1);

            // The lookup table only contains data for one quadrant (since sin is symmetric around both
            // axes), so here we figure out which quadrant we're in, then we lookup the values in the
            // table then modify values accordingly
            bool is_odd_quadrant = (_angle & QUADRANT_LOW_MASK) == 0;
            bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

            if (!is_odd_quadrant) {
                index = SINE_TABLE_SIZE - 1 - index;
            }

            bytes memory table = sin_table;
            // We are looking for two consecutive indices in our lookup table
            // Since EVM is left aligned, to read n bytes of data from idx i, we must read from `i * data_len` + `n`
            // therefore, to read two entries of size entry_bytes `index * entry_bytes` + `entry_bytes * 2`
            uint256 offset1_2 = (index + 2) * entry_bytes;

            // This following snippet will function for any entry_bytes <= 15
            uint256 x1_2;
            assembly {
                // mload will grab one word worth of bytes (32), as that is the minimum size in EVM
                x1_2 := mload(add(table, offset1_2))
            }

            // We now read the last two numbers of size entry_bytes from x1_2
            // in example: entry_bytes = 4; x1_2 = 0x00...12345678abcdefgh
            // therefore: entry_mask = 0xFFFFFFFF

            // 0x00...12345678abcdefgh >> 8*4 = 0x00...12345678
            // 0x00...12345678 & 0xFFFFFFFF = 0x12345678
            uint256 x1 = (x1_2 >> (8 * entry_bytes)) & entry_mask;
            // 0x00...12345678abcdefgh & 0xFFFFFFFF = 0xabcdefgh
            uint256 x2 = x1_2 & entry_mask;

            // Approximate angle by interpolating in the table, accounting for the quadrant
            uint256 approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
            int256 sine = is_odd_quadrant
                ? int256(x1) + int256(approximation)
                : int256(x2) - int256(approximation);
            if (is_negative_quadrant) {
                sine *= -1;
            }

            // Bring result from the range of -2,147,483,647 through 2,147,483,647 to -1e18 through 1e18.
            // This can never overflow because sine is bounded by the above values
            return (sine * 1e18) / 2_147_483_647;
        }
    }

    /**
     * @notice Return the cosine of a value, specified in radians scaled by 1e18
     * @dev This is identical to the sin() method, and just computes the value by delegating to the
     * sin() method using the identity cos(x) = sin(x + pi/2)
     * @dev Overflow when `angle + PI_OVER_TWO > type(uint256).max` is ok, results are still accurate
     * @param _angle Angle to convert
     * @return Result scaled by 1e18
     */
    function cos(uint256 _angle) internal pure returns (int256) {
        unchecked {
            return sin(_angle + PI_OVER_TWO);
        }
    }
}

//SPDX-License-Identifier: MIT
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        unchecked {
            if (x == MIN_64x64) {
                require(
                    y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                        y <= 0x1000000000000000000000000000000000000000000000000
                );
                return -y << 63;
            } else {
                bool negativeResult = false;
                if (x < 0) {
                    x = -x;
                    negativeResult = true;
                }
                if (y < 0) {
                    y = -y; // We rely on overflow behavior here
                    negativeResult = !negativeResult;
                }
                uint256 absoluteResult = mulu(x, uint256(y));
                if (negativeResult) {
                    require(
                        absoluteResult <=
                            0x8000000000000000000000000000000000000000000000000000000000000000
                    );
                    return -int256(absoluteResult); // We rely on overflow behavior here
                } else {
                    require(
                        absoluteResult <=
                            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                    );
                    return int256(absoluteResult);
                }
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) *
                (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(
                hi <=
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
                        lo
            );
            return hi + lo;
        }
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);

            bool negativeResult = false;
            if (x < 0) {
                x = -x; // We rely on overflow behavior here
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint128 absoluteResult = divuu(uint256(x), uint256(y));
            if (negativeResult) {
                require(absoluteResult <= 0x80000000000000000000000000000000);
                return -int128(absoluteResult); // We rely on overflow behavior here
            } else {
                require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(absoluteResult); // We rely on overflow behavior here
            }
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            return int128((int256(x) + int256(y)) >> 1);
        }
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 m = int256(x) * int256(y);
            require(m >= 0);
            require(
                m <
                    0x4000000000000000000000000000000000000000000000000000000000000000
            );
            return int128(sqrtu(uint256(m)));
        }
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return
                int128(
                    int256(
                        (uint256(int256(log_2(x))) *
                            0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
                    )
                );
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0)
                result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0)
                result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0)
                result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0)
                result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0)
                result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0)
                result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0)
                result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0)
                result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0)
                result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0)
                result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0)
                result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0)
                result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0)
                result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0)
                result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0)
                result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0)
                result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0)
                result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0)
                result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0)
                result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0)
                result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0)
                result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0)
                result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0)
                result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0)
                result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0)
                result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0)
                result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0)
                result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0)
                result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0)
                result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0)
                result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0)
                result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0)
                result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0)
                result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0)
                result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0)
                result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0)
                result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0)
                result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0)
                result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0)
                result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0)
                result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0)
                result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0)
                result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0)
                result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0)
                result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0)
                result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0)
                result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0)
                result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0)
                result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0)
                result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0)
                result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0)
                result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0)
                result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0)
                result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0)
                result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0)
                result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0)
                result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0)
                result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0)
                result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0)
                result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0)
                result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0)
                result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0)
                result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0)
                result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return
                exp_2(
                    int128(
                        (int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128
                    )
                );
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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
    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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

        /// @solidity memory-safe-assembly
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

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
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