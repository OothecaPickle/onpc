/*
 * Copyright (C) 2019. Mikhail Kulesh
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details. You should have received a copy of the GNU General
 * Public License along with this program.
 */

import "package:flutter/material.dart";

import "../constants/Drawables.dart";
import "../constants/Strings.dart";
import "../dialogs/AudioControlDialog.dart";
import "../iscp/ISCPMessage.dart";
import "../iscp/StateManager.dart";
import "../iscp/messages/AudioMutingMsg.dart";
import "../iscp/messages/MasterVolumeMsg.dart";
import "../iscp/messages/PowerStatusMsg.dart";
import "../iscp/state/SoundControlState.dart";
import "../utils/Logging.dart";
import "../widgets/CustomImageButton.dart";
import "UpdatableView.dart";

class DeviceVolumeButtonsView extends UpdatableView
{
    static const List<String> UPDATE_TRIGGERS = [
        StateManager.ZONE_EVENT,
        PowerStatusMsg.CODE,
        AudioMutingMsg.CODE,
        MasterVolumeMsg.CODE
    ];

    DeviceVolumeButtonsView(final ViewContext viewContext) : super(viewContext, UPDATE_TRIGGERS);

    @override
    Widget createView(BuildContext context, VoidCallback updateCallback)
    {
        Logging.info(this, "rebuild widget");

        final SoundControlState soundControl = state.soundControlState;
        final bool volumeValid = state.isOn && soundControl.volumeLevel != MasterVolumeMsg.NO_LEVEL;

        final List<ZonedMessage> cmd = [
            AudioMutingMsg.output(state.getActiveZone, AudioMuting.TOGGLE),
            MasterVolumeMsg.output(state.getActiveZone, MasterVolume.DOWN),
            MasterVolumeMsg.output(state.getActiveZone, MasterVolume.UP)
        ];

        final List<Widget> buttons = List<Widget>();
        cmd.forEach((cmd)
        {
            String icon, description;
            bool selected = false;
            if (cmd is AudioMutingMsg)
            {
                icon = cmd.getValue.icon;
                description = cmd.getValue.description;
                selected = state.isOn && soundControl.audioMuting.key == AudioMuting.ON;
            }
            else if (cmd is MasterVolumeMsg)
            {
                icon = cmd.getCommand.icon;
                description = cmd.getCommand.description;
            }

            buttons.add(CustomImageButton.normal(
                icon,
                description,
                onPressed: ()
                => stateManager.sendMessage(cmd),
                isEnabled: state.isOn,
                isSelected: selected
            ));
        });

        // master volume label
        {
            final String volumeLevel = SoundControlState.getVolumeLevelStr(
                soundControl.volumeLevel, state.getActiveZoneInfo);

            buttons.insert(2, CustomImageButton.normal(
                Drawables.volume_audio_control,
                Strings.audio_control,
                text: volumeValid ? volumeLevel : "",
                onPressed: ()
                => _showAudioControlDialog(context),
                isEnabled: volumeValid
            ));
        }

        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: buttons,
        );
    }

    void _showAudioControlDialog(final BuildContext context)
    {
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext c)
            => AudioControlDialog(viewContext, AudioControlType.TONE_CONTROL)
        );
    }
}