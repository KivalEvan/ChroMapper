﻿using Beatmap.Base;
using Beatmap.Base.Customs;
using SimpleJSON;

namespace Beatmap.V3.Customs
{
    public static class V3EnvironmentEnhancement
    {
        public const string KeyID = "id";

        public const string KeyLookupMethod = "lookupMethod";

        public const string KeyGeometry = "geometry";

        public const string KeyTrack = "track";

        public const string KeyDuplicate = "duplicate";

        public const string KeyActive = "active";

        public const string KeyScale = "scale";

        public const string KeyPosition = "position";

        public const string KeyRotation = "rotation";

        public const string KeyLocalPosition = "localPosition";

        public const string KeyLocalRotation = "localRotation";

        public const string KeyComponents = "components";

        public const string KeyLightID = "lightID";

        public const string KeyLightType = "type";

        public const string GeometryKeyType = "type";

        public const string GeometryKeyMaterial = "material";

        public static BaseEnvironmentEnhancement GetFromJson(JSONNode node) => new BaseEnvironmentEnhancement(node);

        public static JSONNode ToJson(BaseEnvironmentEnhancement environment)
        {
            var node = new JSONObject();
            if (environment.Geometry != null)
            {
                node[KeyGeometry] = environment.Geometry;
            }
            else
            {
                node[KeyID] = environment.ID;
                node[KeyLookupMethod] = environment.LookupMethod.ToString();
            }

            if (!string.IsNullOrEmpty(environment.Track)) node[KeyTrack] = environment.Track;
            if (environment.Duplicate > 0) node[KeyDuplicate] = environment.Duplicate;
            if (environment.Active != null) node[KeyActive] = environment.Active;
            if (environment.Scale != null) BaseEnvironmentEnhancement.WriteVector3(node, KeyScale, environment.Scale);
            if (environment.Position != null) BaseEnvironmentEnhancement.WriteVector3(node, KeyPosition, environment.Position);
            if (environment.Rotation != null) BaseEnvironmentEnhancement.WriteVector3(node, KeyRotation, environment.Rotation);
            if (environment.LocalPosition != null) BaseEnvironmentEnhancement.WriteVector3(node, KeyLocalPosition, environment.LocalPosition);
            if (environment.LocalRotation != null) BaseEnvironmentEnhancement.WriteVector3(node, KeyLocalRotation, environment.LocalRotation);
            if (environment.Components != null) node[KeyComponents] = environment.Components;

            return node;
        }
    }
}
