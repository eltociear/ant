#pragma once
#include "font.h"

#include <RmlUi/RenderInterface.h>
#include <algorithm>
#include <unordered_map>
#include <bgfx/c99/bgfx.h>

// Same as BGFX
enum SamplerFlag : uint32_t {
    U_MIRROR        = 0x00000001,
    U_CLAMP         = 0x00000002,
    U_BORDER        = 0x00000003,
    U_SHIFT         = 0,
    U_MASK          = 0x00000003,

    V_MIRROR        = 0x00000004,
    V_CLAMP         = 0x00000008,
    V_BORDER        = 0x0000000c,
    V_SHIFT         = 2,
    V_MASK          = 0x0000000c,

    MIN_POINT       = 0x00000040,
    MIN_ANISOTROPIC = 0x00000080,
    MIN_SHIFT       = 6,
    MIN_MASK        = 0x000000c0,

    MAG_POINT       = 0x00000100,
    MAG_ANISOTROPIC = 0x00000200,
    MAG_SHIFT       = 8,
    MAG_MASK        = 0x00000300,

    MIP_POINT       = 0x00000400,
    MIP_SHIFT       = 10,
    MIP_MASK        = 0x00000400,
};

class TransientIndexBuffer32{
public:
    TransientIndexBuffer32(uint32_t sizeBytes = 1024*1024*sizeof(uint32_t));
    ~TransientIndexBuffer32();
    void SetIndex(bgfx_encoder_t *encoder, int *indices, int num);
    void Reset();
private:
    uint32_t moffset;
    uint32_t msize;
    const bgfx_dynamic_index_buffer_handle_t  mdyn_indexbuffer;
};

class Renderer : public Rml::RenderInterface {
public:
    Renderer(const RmlContext* context);
    virtual void RenderGeometry(Rml::Vertex* vertices, int num_vertices, 
                                int* indices, int num_indices, 
                                Rml::TextureHandle texture) override;

	virtual void SetScissorRegion(Rml::Rect const& clip) override;
    virtual bool LoadTexture(Rml::TextureHandle& texture_handle, Rml::Size& texture_dimensions, const Rml::String& source) override;
    virtual bool GenerateTexture(Rml::TextureHandle& texture_handle, const Rml::byte* source, const Rml::Size& source_dimensions) override;
    virtual void ReleaseTexture(Rml::TextureHandle texture) override;
    virtual void SetTransform(const glm::mat4x4& transform) override{
        mTransform = transform;
        mScissorRect.updateTransform(mTransform);
    }

public:
    // will delete buffer
    bool UpdateTexture(Rml::TextureHandle texhandle, const Rect &rt, uint8_t *buffer);
    void Begin();
    void Frame();

public:
    void UpdateViewRect();
    // bool CalcScissorRectPlane(const glm::mat4 &transform, const Rect &rect, glm::vec4 planes[4]);
    // void SubmitScissorRect();

private:
    glm::mat4x4             mTransform;
    const RmlContext*       mcontext;
    TransientIndexBuffer32  mIndexBuffer;

    bgfx_encoder_t*         mEncoder;

    struct ScissorRect{
        Rect scissorRect {0, 0, 0, 0};
        glm::vec4 rectVerteices[2]{glm::vec4(0), glm::vec4(0)};
        bool needShaderClipRect = false;
        void updateScissorRect(const glm::mat4 &m, const Rml::Rect& clip);
        void updateTransform(const glm::mat4 &m);
        void submitScissorRect(bgfx_encoder_t* encoder, const shader_info &si);
        Rect get();
    };

    ScissorRect mScissorRect;
};
