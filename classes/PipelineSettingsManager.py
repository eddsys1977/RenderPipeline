
from SettingsManager import SettingsManager


class PipelineSettingsManager(SettingsManager):

    """ This class is a wrapper arround SettingsManager and
    stores the settings (and their defaults) used by RenderPipeline. """

    def __init__(self):
        """ Constructs a new PipelineSettingsManager. Remember to call
        loadFromFile to load actual settings instead of the defaults. """
        SettingsManager.__init__(self, "PipelineSettings")

    def _addDefaultSettings(self):
        """ Internal method which populates the settings array with defaults
        and the internal type of settings (like int, bool, ...) """
        # [Antialiasing]
        self._addSetting("antialiasingTechnique", str, "SMAA")

        # [Lighting]
        self._addSetting("computePatchSizeX", int, 32)
        self._addSetting("computePatchSizeY", int, 32)
        self._addSetting("minMaxDepthAccuracy", int, 3)
        self._addSetting("anyLightBoundCheck", bool, True)
        self._addSetting("accurateLightBoundCheck", bool, True)

        # [Shadows]
        self._addSetting("renderShadows", bool, True)
        self._addSetting("shadowAtlasSize", int, 8192)
        self._addSetting("maxShadowUpdatesPerFrame", int, 2)
        self._addSetting("numShadowSamples", int, 8)

        # [Motion blur]
        self._addSetting("motionBlurSamples", int, 8)
        self._addSetting("motionBlurFactor", float, 1.0)

        # [Debugging]
        self._addSetting("displayShadowAtlas", bool, True)
