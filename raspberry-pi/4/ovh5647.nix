{ config, lib, ... }:

let
  cfg = config.hardware.raspberry-pi."4".ovh5647;
in {
  options.hardware = {
    raspberry-pi."4".ov5647 = {
      enable = lib.mkEnableOption ''
        support for the ov5647
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = lib.mkDefault true;
    # doesn't work for the CM module, so we exclude e.g. bcm2711-rpi-cm4.dts
    hardware.deviceTree.filter = "bcm2711-rpi-4*.dtb";

    hardware.deviceTree = {
      overlays = [
        # bcm2835 -> bcm2711
        # Equivalent to: https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/ov5647-overlay.dts
        {
          name = "ov5647-overlay";
          dtsText = ''
            // SPDX-License-Identifier: GPL-2.0-only
            // Definitions for OV5647 camera module on VC I2C bus
            /dts-v1/;
            /plugin/;

            /{
            	compatible = "brcm,bcm2711";

            	i2c_frag: fragment@0 {
            		target = <&i2c_csi_dsi>;
            		__overlay__ {
            			#address-cells = <1>;
            			#size-cells = <0>;
            			status = "okay";

            			#include "ov5647.dtsi"

            			vcm: ad5398@c {
            				compatible = "adi,ad5398";
            				reg = <0x0c>;
            				status = "disabled";
            				VANA-supply = <&cam1_reg>;
            			};
            		};
            	};

            	csi_frag: fragment@1 {
            		target = <&csi1>;
            		csi: __overlay__ {
            			status = "okay";
            			brcm,media-controller;

            			port {
            				csi_ep: endpoint {
            					remote-endpoint = <&cam_endpoint>;
            					data-lanes = <1 2>;
            				};
            			};
            		};
            	};

            	fragment@2 {
            		target = <&i2c0if>;
            		__overlay__ {
            			status = "okay";
            		};
            	};

            	fragment@3 {
            		target = <&i2c0mux>;
            		__overlay__ {
            			status = "okay";
            		};
            	};

            	reg_frag: fragment@4 {
            		target = <&cam1_reg>;
            		__overlay__ {
            			startup-delay-us = <20000>;
            		};
            	};

            	clk_frag: fragment@5 {
            		target = <&cam1_clk>;
            		__overlay__ {
            			status = "okay";
            			clock-frequency = <25000000>;
            		};
            	};

            	__overrides__ {
            		rotation = <&cam_node>,"rotation:0";
            		orientation = <&cam_node>,"orientation:0";
            		media-controller = <&csi>,"brcm,media-controller?";
            		cam0 = <&i2c_frag>, "target:0=",<&i2c_vc>,
            		       <&csi_frag>, "target:0=",<&csi0>,
            		       <&reg_frag>, "target:0=",<&cam0_reg>,
            		       <&clk_frag>, "target:0=",<&cam0_clk>,
            		       <&cam_node>, "clocks:0=",<&cam0_clk>,
            		       <&cam_node>, "avdd-supply:0=",<&cam0_reg>;
            		vcm = <&vcm>, "status=okay",
            		      <&cam_node>,"lens-focus:0=", <&vcm>;
            	};
            };

            &cam_node {
            	status = "okay";
            };

            &cam_endpoint {
            	remote-endpoint = <&csi_ep>;
            };
          '';
        }
      ];
    };
  };
}
