{ config, lib, ... }:

let
  cfg = config.hardware.raspberry-pi."4".sense-hat;
in {
  options.hardware = {
    raspberry-pi."4".sense-hat = {
      enable = lib.mkEnableOption ''
        support for the Raspberry Pi Sense v1.0 Hat.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = lib.mkDefault true;
    # doesn't work for the CM module, so we exclude e.g. bcm2711-rpi-cm4.dts
    hardware.deviceTree.filter = "bcm2711-rpi-4*.dtb";

    hardware.deviceTree = {
      overlays = [
        # Equivalent to: https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/rpi-sense-overlay.dts
        {
          name = "rpi-sense-overlay";
          dtsText = ''
            // rpi-sense HAT
            /dts-v1/;
            /plugin/;
            
            / {
            	compatible = "brcm,bcm2711";
            
            	fragment@0 {
            		target = <&i2c1>;
            		__overlay__ {
            			#address-cells = <1>;
            			#size-cells = <0>;
            			status = "okay";
            
            			rpi-sense@46 {
            				compatible = "rpi,rpi-sense";
            				reg = <0x46>;
            				keys-int-gpios = <&gpio 23 1>;
            				status = "okay";
            			};
            
            			lsm9ds1-magn@1c {
            				compatible = "st,lsm9ds1-magn";
            				reg = <0x1c>;
            				status = "okay";
            			};
            
            			lsm9ds1-accel6a {
            				compatible = "st,lsm9ds1-accel";
            				reg = <0x6a>;
            				status = "okay";
            			};
            
            			lps25h-press@5c {
            				compatible = "st,lps25h-press";
            				reg = <0x5c>;
            				status = "okay";
            			};
            
            			hts221-humid@5f {
            				compatible = "st,hts221-humid", "st,hts221";
            				reg = <0x5f>;
            				status = "okay";
            			};
            		};
            	};
            };
          '';
        }
      ];
    };
  };
}
